#!/usr/bin/env perl

use Test::Most tests => 1;
use SSW::Data::BundleRoot;
use Path::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Digest::SHA qw(sha256_hex);

use constant TESTING => 0;
use constant TESTING_DIR => path('ssw-test');

subtest "Create data bundle" => sub {
	my @opt = TESTING ? ( DIR => TESTING_DIR, CLEANUP => 0 ) : ();
	path({@opt}->{DIR})->mkpath if( {@opt}->{DIR} );
	my $src_tmp_dir = TESTING
		? TESTING_DIR->child('src')
		: Path::Tiny->tempdir( TEMPLATE => 'src-XXXXXX' , @opt );
	my $bundle_root_tmp_dir = TESTING
		? TESTING_DIR->child('bundle-root')
		: Path::Tiny->tempdir( TEMPLATE => 'bundle-root-XXXXXX', @opt );

	my @files = (
		{
			src_name => '01_abc.tiff',
			text => 'abc',
			mtime => 123 * 1e5,

			bundle => {
				name => '01_abc',
				archive => $bundle_root_tmp_dir->child("bundle/01_abc/.archive.zip"),
				sha256 => 'edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb',
				extension => '.tiff',
			},
		},
		{
			src_name => '02_def.pdf',
			text => 'def',
			mtime => 345 * 1e5,

			bundle => {
				name => '02_def',
				archive => $bundle_root_tmp_dir->child("bundle/02_def/.archive.zip"),
				sha256 => 'da1464fd7ceaf38ff56043bc1774af4fb5cb83ef5358981d78de0b8be5a6fbcb',
				extension => '.pdf',
			},
		},
		{
			src_name => 'under/neath/03_ghi.pdf',
			text => 'ghi',
			mtime => 678 * 1e5,

			bundle => {
				name => 'under--neath--03_ghi',
				archive => $bundle_root_tmp_dir->child("bundle/under--neath--03_ghi/.archive.zip"),
				sha256 => '8807953138274f7bd417673cde9848823b1fe720b5ed7b01f8fa00681a456da0',
				extension => '.pdf',
			},
		},
		{
			src_name => '04_copy_of_abc.tiff',
			text => 'abc',
			mtime => 901 * 1e5,

			expected_path => '01_abc.tiff',
			expected_mtime => 123 * 1e5,

			bundle => {
				name => '01_abc', # same checksum
				archive => $bundle_root_tmp_dir->child("bundle/01_abc/.archive.zip"),
				sha256 => 'edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb',
				extension => '.tiff',
			},
		},
		{
			src_name => 'yet/another/05_copy_of_abc.tiff',
			text => 'abc',
			mtime => 234 * 1e5,

			expected_path => '01_abc.tiff',
			expected_mtime => 123 * 1e5,

			bundle => {
				name => '01_abc', # same checksum
				archive => $bundle_root_tmp_dir->child("bundle/01_abc/.archive.zip"),
				sha256 => 'edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb',
				extension => '.tiff',
			},
		},
		{
			src_name => '01_abc.pdf',
			text => 'something different from 01_abc.tiff',
			mtime => 123 * 1e5,

			bundle => {
				name => '01_abc-01', # different checksum, so add suffix
				archive => $bundle_root_tmp_dir->child("bundle/01_abc-01/.archive.zip"),
				sha256 => 'c61dc387628d3d482c90adb3f9598ff319fa6b655961c5987ed4a40ffef895bc',
				extension => '.pdf',
			},
		},
	);

	my $br = SSW::Data::BundleRoot->new(
		bundle_root_path => $bundle_root_tmp_dir
	);

	for my $file_info (@files) {
		$file_info->{src} = $src_tmp_dir->child($file_info->{src_name});
		$file_info->{src}->parent->mkpath;
		$file_info->{src}->spew_utf8( $file_info->{text} . "\n" );
		$file_info->{src}->touch( $file_info->{mtime} );

		unless( exists $file_info->{expected_path} ) {
			$file_info->{expected_path} = $file_info->{src_name};
		}
		unless( exists $file_info->{expected_mtime} ) {
			$file_info->{expected_mtime} = $file_info->{mtime};
		}
	}

	my @bundles;
	for my $file (@files) {
		my $bundle = $br->create_or_find_bundle_for_file(
			$file->{src},
			$src_tmp_dir,
		);
		subtest "Bundle: $file->{src_name} -> $file->{bundle}{name}" => sub {

			subtest "Check bundle name" => sub {
				is $bundle->bundle_name, $file->{bundle}{name}, 'check bundle name';

				is $bundle->bundle_name, $bundle->data_bundle_name,
					'bundle name via path and bundle name via data are the same';
			};

			subtest "Check bundle archive path" => sub {
				ok $bundle->_bundle_archive->is_file, 'archive file exists';
				is $bundle->_bundle_archive, $file->{bundle}{archive}->absolute, 'check bundle archive path';
			};

			subtest "Check bundle data" => sub {
				is $bundle->data_path, $file->{expected_path}, 'check original source path via data';
				is $bundle->data_extension, $file->{bundle}{extension}, 'check extension via data';
				is $bundle->data_mtime, $file->{expected_mtime}, 'check mtime via data';
				is $bundle->data_sha256, $file->{bundle}{sha256}, 'check bundle attribute sha256 via data';
				is $bundle->data_bundle_name, $file->{bundle}{name}, 'check bundle name via data';
			};

			subtest "Check data via archive members" => sub {
				my $zip = Archive::Zip->new;
				ok $zip->read( $bundle->_bundle_archive->stringify ) == AZ_OK, 'can read archive';
				ok my $member = $zip->memberNamed( $file->{expected_path} ), 'has file with expected source path';

				if( $member ) {
					is sha256_hex(scalar $member->contents), $file->{bundle}{sha256}, 'bundle archive contents sha256';
				}
			};

			subtest "Check data via metadata" => sub {
				my $meta = $br->_json->decode( $bundle->_bundle_meta->slurp_utf8 );
				is_deeply $meta->{'-simple-scan-workflow'}, { metadata_version => 1, }, 'version 1 of metadata';
				is_deeply $meta->{data}, $bundle->data, 'data';
			};
		};

		push @bundles, $bundle;
	}


	pass;
};

done_testing;

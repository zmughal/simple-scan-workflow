#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';

use Path::Tiny;

use SSW::Data::BundleRoot;
use SSW::StepWorkflow;

use TestDuckling;

my $d = TestDuckling->new;
$d->start_duckling;

my $src_tmp_dir = path("/tmp/abc");
	#Path::Tiny->tempdir( TEMPLATE => 'src-XXXXXX' );
my $bundle_root_tmp_dir = path("/tmp/bundle-root-012");
	#Path::Tiny->tempdir( TEMPLATE => 'bundle-root-XXXXXX' );

my $br = SSW::Data::BundleRoot->new(
	bundle_root_path => $bundle_root_tmp_dir
);

my @files = (
	{
		src_name => '01_abc.tiff',
		text => <<~EOF
			The Title of the Document

			There are some dates in here such as January 2nd, 2008. But we
			can also talk about 1/23/2008. Or 3rd of Feb.
			Or maybe the 29th of February.
			EOF
	},
);

for my $file_info (@files) {
	$file_info->{src} = $src_tmp_dir->child($file_info->{src_name});
	$file_info->{src}->parent->mkpath;

	system( qw(convert),
		qw(-depth 8),
		qw(-type truecolor),
		qw(-size 150),
		"pango:@{[ $file_info->{text} ]}",
		$file_info->{src}
	);
}

subtest "Test workflow" => sub {
	for my $file_info (@files) {
		my $bundle = $br->create_or_find_bundle_for_file(
			$file_info->{src},
			$src_tmp_dir,
		);

		my $workflow = SSW::StepWorkflow->new(
			bundle => $bundle,
		);
		$workflow->run;

		use Data::Dumper;
		diag Dumper $workflow->_steps->[-1]->read_meta;
	}
	pass;
};

END {
	$d->stop_duckling;
}

done_testing;

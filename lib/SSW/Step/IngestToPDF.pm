package SSW::Step::IngestToPDF;
# ABSTRACT: Take a source file from archive to PDF

use Mu;
use SSW::Data::BundleRoot;
use autodie qw(:all);

use File::chdir;
use Capture::Tiny qw(capture_stdout);
use Path::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub run {
	my ($self) = @_;

	my $zip = Archive::Zip->new;
	$zip->read( $self->bundle->_bundle_archive->stringify ) == AZ_OK
		or die "Could not extract archive";

	my $file;
	if( $self->bundle->data_extension =~ $SSW::Data::BundleRoot::FILE_EXTENSIONS_RE ) {
		my $temp_dir = Path::Tiny->tempdir;
		local $CWD = $temp_dir;
		$zip->extractMemberWithoutPaths( $self->bundle->data_path );
		my $path_to_temp = $temp_dir->child(path($self->bundle->data_path)->basename);

		die "Unable to extract to temporary directory" unless -f $path_to_temp;

		$file = $self->_directory_for_step->child($self->bundle->bundle_name . '.pdf');
		$file->parent->mkpath;

		if( $self->bundle->data_extension eq '.pdf' ) {
			$path_to_temp->copy( $file );
		} else {
			system( qw(img2pdf),
				qw(--output), $file,
				$path_to_temp,
			);
		}
	} else {
		die <<~EOF;
		Do not know how to ingest bundle @{[ $self->bundle->data_name ]}
		with extension @{[ $self->bundle->data_extension ]}
		EOF
	}

	# TODO
	$self->output( $file );
}

with qw(SSW::Role::Stepable);

1;

package SSW::Action::OCR::OCRmyPDF;
# ABSTRACT: «TODO»

use Mu;
use CLI::Osprey;
use Path::Tiny;
use IPC::System::Simple ();
use autodie qw(:all);

sub run {
	my ($self) = @_;
	my ($input, $output) = ( path($self->input), path($self->output) );
	-f $input or die "input file must exist";

	my $exit = system(
			qw(ocrmypdf),
			$input->absolute,
			$output->absolute,
			qw(--sidecar), $self->sidecar_file->absolute,
	);

	die "OCR failed" unless $exit == 0;
	die "OCR PDF not generated" unless -f $output;
	die "Sidecar not generated" unless -f $self->sidecar_file;
}

with qw(SSW::Role::OCRable SSW::Role::OCRable::Sidecar);

1;

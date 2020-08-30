package SSW::Action::OCR::OCRmyPDF;
# ABSTRACT: Action to run OCRmyPDF OCR pipeline

use Mu;
use CLI::Osprey;
use Path::Tiny;
use IPC::System::Simple ();
use autodie qw(:all);
use Log::Any qw($log);

sub run {
	my ($self) = @_;
	my ($input, $output) = ( path($self->input), path($self->output) );
	-f $input or die "input file must exist";

	$log->info('Running OCRmyPDF', { input => "$input", output => "$output" });
	my $exit = system(
			qw(ocrmypdf),
			$input->absolute,
			$output->absolute,
			qw(--sidecar), $self->sidecar_file->absolute,
	);

	die $log->error("OCR failed",
		{ exit => $exit }) unless $exit == 0;
	die $log->error("OCR PDF not generated",
		{ output => $output}) unless -f $output;
	die $log->error("Sidecar not generated",
		{ sidecar => $self->sidecar_file })
		unless -f $self->sidecar_file;
}

with qw(SSW::Role::OCRable SSW::Role::OCRable::Sidecar);

1;

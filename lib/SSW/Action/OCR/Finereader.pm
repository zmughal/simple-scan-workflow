package SSW::Action::OCR::Finereader;
# ABSTRACT: Action to run ABBYY FineReader OCR

use Moo;
use CLI::Osprey;
use Path::Tiny;
use FindBin::libs qw( export scalar base=applescript );
use Log::Any qw($log);

sub run {
	my ($self) = @_;
	my ($input, $output) = ( path($self->input), path($self->output) );
	-f $input or die "input file must exist";

	my $path_to_finereader_script = path($applescript)->child(qw(abby-finereader-ocr-pdf.scpt));
	$log->info('Running FineReader', { input => "$input", output => "$output" });
	my $exit = system(
			qw(osascript),
			$path_to_finereader_script,
			$input->absolute,
			$output->absolute,
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

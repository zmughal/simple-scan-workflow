package SSW::Action::OCR::pdfsandwich;
# ABSTRACT: Action to run pdfsandwich OCR pipeline

use Moo;
use CLI::Osprey;
use Path::Tiny;
use Log::Any qw($log);

sub run {
	my ($self) = @_;
	my ($input, $output) = ( path($self->input), path($self->output) );
	-f $input or die "input file must exist";

	$log->info('Running pdfsandwich', { input => "$input", output => "$output" });
	my $exit = system(
			qw(pdfsandwich),
			qw(-nopreproc),
			qw(-o), $output->absolute,
			$input->absolute,
	);

	die "OCR failed" unless $exit == 0;
}

with qw(SSW::Role::OCRable);

1;

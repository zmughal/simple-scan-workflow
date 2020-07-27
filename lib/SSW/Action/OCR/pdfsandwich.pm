package SSW::Action::OCR::pdfsandwich;
# ABSTRACT: «TODO»

use Moo;
use CLI::Osprey;
use Path::Tiny;

sub run {
	my ($self) = @_;
	my ($input, $output) = path($self->input), path($self->output);
	-f $input or die "input file must exist";

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

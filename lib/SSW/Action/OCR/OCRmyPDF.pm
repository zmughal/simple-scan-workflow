package SSW::Action::OCR::OCRmyPDF;
# ABSTRACT: «TODO»

use Moo;
use CLI::Osprey;
use Path::Tiny;
use IPC::System::Simple ();
use autodie qw(:all);

sub run {
	my ($self) = @_;
	my ($input, $output) = path($self->input), path($self->output);
	-f $input or die "input file must exist";

	...
}

with qw(SSW::Role::OCRable);

1;

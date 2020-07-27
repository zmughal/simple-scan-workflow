package SSW::Action::OCR;
# ABSTRACT: «TODO»

use Moo;
use CLI::Osprey;
use File::Which;

use SSW::Action::OCR::Finereader;
use SSW::Action::OCR::pdfsandwich;
use SSW::Action::OCR::OCRmyPDF;

sub run {
	my ($self) = @_;
	my @opt = (
		input => $self->input, output => $self->output,
		parent_command => $self, invoked_as => "$0 ocr",
	);
	if( $^O eq 'darwin' ) {
		SSW::Action::OCR::Finereader->new_with_options( @opt  )->run;
	} elsif( which('ocrmypdf') ) {
		SSW::Action::OCR::OCRmyPDF->new_with_options( @opt )->run;
	} elsif( which('pdfsandwich') ) {
		SSW::Action::OCR::pdfsandwich->new_with_options( @opt )->run;
	}

}

with qw(SSW::Role::OCRable);

1;

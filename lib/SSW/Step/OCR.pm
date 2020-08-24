package SSW::Step::OCR;
# ABSTRACT: Run OCR on a PDF

use Mu;
use autodie qw(:all);

use SSW::Action::OCR;

sub run {
	my ($self) = @_;

	my $output = $self->_directory_for_step
		->child($self->bundle->bundle_name . '-ocr.pdf');
	$output->parent->mkpath;

	my $ocr = SSW::Action::OCR->new(
		input => $self->previous_step->output,
		output => $output,
	);
	$ocr->run;

	$self->output( $output );
}

with qw(SSW::Role::Stepable);

1;

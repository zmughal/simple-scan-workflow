package SSW::Step::OCR;
# ABSTRACT: Run OCR on a PDF

use Mu;
use autodie qw(:all);
use Path::Tiny;

use SSW::Action::OCR;

sub run {
	my ($self) = @_;

	my $output = $self->_directory_for_step
		->child($self->bundle->bundle_name . '-ocr.pdf');
	$output->parent->mkpath;

	my $ocr = SSW::Action::OCR->new(
		input => path($self->previous_step->output)
			->absolute( $self->workflow->_workflow_dir ),
		output => $output,
	);
	$ocr->run;

	$self->output( $output->relative( $self->workflow->_workflow_dir ) );
}

with qw(SSW::Role::Stepable);

1;

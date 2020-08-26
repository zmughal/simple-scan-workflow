package SSW::StepWorkflow;
# ABSTRACT: A workflow to run on a bundle

use Mu;
use autodie qw(:all);

use SSW::Step::IngestToPDF;
use SSW::Step::OCR;
use SSW::Step::Rename;

lazy _name => sub {
	'pdf-naming',
};

ro 'bundle';

lazy _workflow_dir => sub {
	my ($self) = @_;
	$self->bundle->bundle_path
		->child( qw(.workflow), $self->_name );
};

lazy _steps => sub {
	my ($self) = @_;

	my @steps;

	push @steps, my $ingest = SSW::Step::IngestToPDF->new(
		name => 'ingest-to-pdf',
		bundle => $self->bundle,
		workflow => $self,
	);

	push @steps, my $ocr = SSW::Step::OCR->new(
		name => 'ocr',
		bundle => $self->bundle,
		previous_step => $ingest,
		workflow => $self,
	);

	push @steps, my $rename = SSW::Step::Rename->new(
		name => 'rename',
		bundle => $self->bundle,
		previous_step => $ocr,
		workflow => $self,
	);

	\@steps;
};

sub run {
	my ($self) = @_;

	my @steps = @{ $self->_steps };
	for my $step (@steps) {
		$step->run;
	}
}

1;

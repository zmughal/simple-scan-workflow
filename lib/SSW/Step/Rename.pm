package SSW::Step::Rename;
# ABSTRACT: Extract data to rename file

use Moo;
use autodie qw(:all);
use Path::Tiny;
use Log::Any qw($log);

use SSW::Process::pdftotext;
use SSW::Process::ExtractPDFTitle::FromBeginning;
use SSW::Process::ExtractTime::DucklingFilter;

sub run {
	my ($self) = @_;

	$log->info("Running Step::Rename with bundle @{[ $self->bundle->bundle_name ]}");

	my $pdf_file = path($self->previous_step->output)
		->absolute( $self->workflow->_workflow_dir );
	my $sidecar_file = $pdf_file . '.txt';

	my $text;
	if( -f $sidecar_file ) {
		$text = path($sidecar_file)->slurp_utf8;
	} else {
		my $pdftotext = SSW::Process::pdftotext->new(
			input_file => $pdf_file,
		);
		$pdftotext->process;
		$text = $pdftotext->output_text;
	}

	my $extract = SSW::Process::ExtractPDFTitle::FromBeginning->new(
		input_text => $text,
	);
	$extract->process;


	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $text =~ s/\n/ /gsr,
	);
	$filter->process;


	my $data = {
		'extract-title' => $extract->output_text,
		'extract-time'  => $filter->output_data,
	};

	my $name = "$data->{'extract-time'} - $data->{'extract-title'}";

	my $output = +{
		data => $data,
		basename => $name,
	};

	$self->output( $output );
}

with qw(SSW::Role::Stepable);

1;

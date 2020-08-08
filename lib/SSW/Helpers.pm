package SSW::Helpers;
# ABSTRACT: Set of helper commands

use FindBin;
use Modern::Perl;

use SSW::Action::OCR;

use SSW::Process::pdftotext;
use SSW::Process::ExtractPDFTitle::FromBeginning;
use SSW::Process::ExtractTime::Duckling;

use autodie qw(:all);

use Path::Tiny;

use constant PDF_EXTENSION_W_DOT => '.pdf';
use constant PDF_RE => qr/\.pdf$/i;

use Exporter 'import';
our @EXPORT = qw(apply_ocr_file get_title extract_date PDF_EXTENSION_W_DOT PDF_RE);

sub apply_ocr_file {
	my ($input, $output) = @_;
	# $input: Path::Tiny input file (must exist)
	# $output: Path::Tiny output file
	SSW::Action::OCR->new_with_options(
		input => $input,
		output => $output,
	)->run;
}

sub get_title {
	my ($input_file) = @_;

	my $pdftotext = SSW::Process::pdftotext->new(
		input_file => $input_file,
	);

	$pdftotext->process;

	my $text = $pdftotext->output_text;

	my $extract = SSW::Process::ExtractPDFTitle::FromBeginning->new(
		input_text => $text,
	);

	$extract->process;

	my $title = $extract->output_text;

	my $new_filename = $input_file->basename( PDF_EXTENSION_W_DOT );

	if( $title =~ /\w/ ) {
		$new_filename = $title;
	}

	return $new_filename;
}

sub extract_date {
	my ($input_file) = @_;

	my $pdftotext = SSW::Process::pdftotext->new(
		input_file => $input_file,
	);

	$pdftotext->process;

	my $text = $pdftotext->output_text;

	my $duckling = SSW::Process::ExtractTime::Duckling->new(
		input_text => $text,
	);

	$duckling->process;
}

1;

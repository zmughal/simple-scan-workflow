package SSW::Helpers;
# ABSTRACT: Set of helper commands

use Encode qw(decode_utf8);
use Modern::Perl;
use Path::Tiny;
use Capture::Tiny qw(capture_stdout);
use List::UtilsBy qw(min_by);

use constant PDF_EXTENSION_W_DOT => '.pdf';
use constant PDF_RE => qr/\.pdf$/i;
use constant PDFTOTEXT_PATH => '/usr/local/bin/pdftotext';

use Exporter 'import';
our @EXPORT = qw(apply_ocr_file get_title PDF_EXTENSION_W_DOT PDF_RE);

sub apply_ocr_file {
	my ($input, $output) = @_;
	# $input: Path::Tiny input file (must exist)
	# $output: Path::Tiny output file

	my $path_to_finereader_script = path($FindBin::Bin)->parent->child(qw(applescript abby-finereader-ocr-pdf.scpt));
	my $exit = system(
			qw(osascript),
			$path_to_finereader_script,
			$input->absolute,
			$output->absolute,
	);

	die "OCR failed" unless $exit == 0;
}

sub get_title {
	my ($input_file) = @_;

	my ($stdout, $exit) = capture_stdout {
		system( PDFTOTEXT_PATH, qw(-f 1 -l 5 -enc UTF-8), "$input_file", qw(-) );
	};

	my $text = decode_utf8($stdout);

	# get rid of form feeds (used for pdftotext page breaks)
	$text =~ s/\f/\n/gm;

	$text =~ s/^\s*$//gm;
	$text =~ s/[^\w\s]//gm;
	$text =~ s/^\n//gm;

	my ($line1, $line2) = split(/\n/, $text);
	my ($first_n_chars) = $text =~ /((?:\s*\S){20})/m;

	my $line_title = $line1 && $line2 ? "$line1 $line2" : "";
	my $char_title = $first_n_chars ? $first_n_chars : "";

	my $title = min_by { length $_ }
		grep { $_ !~ /^\s*$/ }
		map { s/\n|(^\s+)|(\s+$)//gr }
		($line_title, $char_title);

	$title ||= "";

	my $new_filename = $input_file->basename( PDF_EXTENSION_W_DOT );

	if( $title =~ /\w/ ) {
		$new_filename = $title;
	}

	return $new_filename;
}



1;

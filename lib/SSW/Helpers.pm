package SSW::Helpers;
# ABSTRACT: Set of helper commands

use FindBin;
use Modern::Perl;

use SSW::Action::OCR;

use SSW::Process::pdftotext;
use SSW::Process::ExtractPDFTitle::FromBeginning;

use autodie qw(:all);

use Path::Tiny;

use LWP::UserAgent;
use JSON::MaybeXS;


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

	my $ua = LWP::UserAgent->new;
	my $response = $ua->post( 'http://0.0.0.0:8000/parse',
		Content => {
			locale => 'en_US',
			#dims => encode_json(['time']),
			text => $text,
		}
	);
	my $js = decode_json( $response->content );

	my @times = grep { $_->{dim} eq 'time' } @$js;
	say "Times: @{[ scalar @times ]}/@{[ scalar @$js ]}";

	use warnings FATAL => 'uninitialized';
	for my $time (@times) {
		my $body = $time->{body};
		my $value;

		my $type = $time->{value}{type};
		if( $type eq 'interval' ) {
			my $interval = exists $time->{value}{from} ? $time->{value}{from} : $time->{value}{to};
			$value = $interval->{value};
		} elsif( $type eq 'value' ) {
			$value = $time->{value}{value};
		} else {
			warn "Unknown type $type";
		}
		say "$body | $value";
	}
	#use DDP; p $js;
}

1;

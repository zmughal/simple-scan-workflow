package SSW::Helpers;
# ABSTRACT: Set of helper commands

use FindBin;
use Encode qw(decode_utf8);
use Modern::Perl;
use File::Which;

use SSW::Action::OCR;

use IPC::System::Simple ();
use autodie qw(:all);

use Path::Tiny;
use Capture::Tiny qw(capture_stdout);
use List::UtilsBy qw(min_by);

use LWP::UserAgent;
use JSON::MaybeXS;


use constant PDF_EXTENSION_W_DOT => '.pdf';
use constant PDF_RE => qr/\.pdf$/i;
use constant PDFTOTEXT_PATH => grep { -x } ('/usr/local/bin/pdftotext', which('pdftotext'));

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

sub extract_date {
	my ($input_file) = @_;

	my ($stdout, $exit) = capture_stdout {
		system( PDFTOTEXT_PATH, qw(-f 1 -l 5 -enc UTF-8), "$input_file", qw(-) );
	};

	my $text = decode_utf8($stdout);

	my $ua = LWP::UserAgent->new;
	my $response = $ua->post( 'http://0.0.0.0:8000/parse',
		Content => {
			locale => 'en_US',
			#dims => encode_json(['time']),
			text => $stdout
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

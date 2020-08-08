package SSW::Process::pdftotext;
# ABSTRACT: Process PDF file with pdftotext utility

use Mu;
use Encode qw(decode_utf8);
use File::Which;
use Capture::Tiny qw(capture_stdout);

use IPC::System::Simple ();
use autodie qw(:all);

use constant PDFTOTEXT_PATH => grep { -x } ('/usr/local/bin/pdftotext', which('pdftotext'));

ro 'input_file';

# TODO perhaps convert this to predicate and only pass page numbers if
# explicitly set?
has [ qw(first_page_number last_page_number) ] => (
	is => 'ro',
	builder => 1,
);

sub _build_first_page_number { 1 }
sub _build_last_page_number  { 5 }

has output_text => ( is => 'rw' );

sub process {
	my ($self) = @_;
	my ($stdout, $exit) = capture_stdout {
		system( PDFTOTEXT_PATH,
			qw(-f), $self->first_page_number,
			qw(-l), $self->last_page_number,
			qw(-enc UTF-8),
			$self->input_file->stringify,
			qw(-) );
	};

	my $text = decode_utf8($stdout);

	$self->output_text( $text );
}

1;

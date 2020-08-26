package SSW::Process::ExtractPDFTitle::FromBeginning;
# ABSTRACT: Extract title from beginning of pdftotext output

use Mu;

use List::UtilsBy qw(min_by);

ro 'input_text';

has output_text => ( is => 'rw' );

sub process {
	my ($self) = @_;

	my $text = $self->input_text;

	# get rid of form feeds (used for pdftotext page breaks)
	$text =~ s/\f/\n/gm;

	$text =~ s/^\s*$//gm;
	$text =~ s/[^\w\s]//gm;
	$text =~ s/^\n//gm;

	my ($line1, $line2) = split(/\n/, $text);
	my ($first_n_chars) = $text =~ /((?:\s*\S){20})/ms;

	my $line_title = $line1 && $line2 ? "$line1 $line2" : "";
	my $char_title = $first_n_chars ? $first_n_chars : "";

	my $title = min_by { length $_ }
		grep { $_ !~ /^\s*$/ }
		map {
			my $clean = $_ =~ s/\n/ /gr;
			$clean =~ s/(^\s+)|(\s+$)//g;
			$clean;
		}
		($line_title, $char_title);

	$title ||= "";

	$self->output_text( $title );
}


1;

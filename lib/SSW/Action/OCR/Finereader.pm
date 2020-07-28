package SSW::Action::OCR::Finereader;
# ABSTRACT: «TODO»

use Moo;
use CLI::Osprey;
use Path::Tiny;
use FindBin::libs qw( export scalar base=applescript );

sub run {
	my ($self) = @_;
	my ($input, $output) = ( path($self->input), path($self->output) );
	-f $input or die "input file must exist";

	my $path_to_finereader_script = path($applescript)->child(qw(abby-finereader-ocr-pdf.scpt));
	my $exit = system(
			qw(osascript),
			$path_to_finereader_script,
			$input->absolute,
			$output->absolute,
	);

	die "OCR failed" unless $exit == 0;
}

with qw(SSW::Role::OCRable);

1;

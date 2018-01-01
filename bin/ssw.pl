#!/usr/bin/env perl
# ABSTRACT: Run OCR and rename on input PDF files

use FindBin;
use lib "$FindBin::Bin/../lib";

use Encode qw(decode_utf8);
use Modern::Perl;
use Path::Tiny;
use Capture::Tiny qw(capture_stdout);
use List::UtilsBy qw(min_by);
use autodie qw(:all);

use constant PDF_EXTENSION_W_DOT => '.pdf';
use constant PDF_RE => qr/\.pdf$/i;
use constant PDFTOTEXT_PATH => '/usr/local/bin/pdftotext';

sub main {
	my $command = shift @ARGV;
	die "need command" unless $command;
	if( $command eq 'workflow' ) {
		command_workflow();
	} elsif( $command eq 'ocr' ) {
		my ($from_file, $to_dir) = @ARGV;
		apply_ocr(path($from_file), path($to_dir));
	} elsif( $command eq 'rename' ) {
		my ($from_file, $to_dir) = @ARGV;
		apply_rename(path($from_file), path($to_dir));
	} elsif( $command eq 'backup' ) {
		my ($from_file, $to_dir) = @ARGV;
		apply_backup(path($from_file), path($to_dir));
	} elsif( $command eq 'output-title' ) {
		my ($from_file) = @ARGV;
		my $path = path($from_file);
		my $title = $path->basename;
		my $title_no_ext = $path->basename( PDF_EXTENSION_W_DOT );
		if( $from_file =~ PDF_RE ) {
			my $new_title = get_title(path($from_file));
			if( $new_title ne $title_no_ext ) {
				$title = $new_title;
			}
		}
		say $title;
	} else {
		die "unknown command $command";
	}
}

sub command_workflow {
	my $dir_arg = shift @ARGV or die "require path as argument";
	my $dir = path($dir_arg)->absolute;

	my $input_dir       = $dir->child('01 input');
	my $ocr_dir         = $dir->child('02 ocr');
	my $rename_dir      = $dir->child('03 rename');
	my $backup_dir      = $dir->child('backup');

	$_->mkpath for ($input_dir, $ocr_dir, $rename_dir, $backup_dir);


	run_ocr($input_dir, $ocr_dir);
	run_rename($ocr_dir, $rename_dir);
	run_backup($rename_dir, $backup_dir);
}

sub run_ocr {
	my ($from_dir, $to_dir) = @_;
	for my $file ( $from_dir->children( PDF_RE ) ) {
		say "Run OCR on file: $file";
		my $new_file = apply_ocr( $file, $to_dir );
		say "\t$file -> $new_file";
	}
}

sub run_rename {
	my ($from_dir, $to_dir) = @_;
	for my $file ( $from_dir->children( PDF_RE ) ) {
		say "Run rename on file: $file";
		my $new_file = apply_rename($file, $to_dir);
		say "\t$file -> $new_file";
	}
}

sub run_backup {
	my ($from_dir, $to_dir) = @_;
	for my $file ( $from_dir->children( PDF_RE ) ) {
		say "Run backup on file: $file";
		my $new_file = apply_backup($file, $to_dir);
		say "\t$file -> $new_file";
	}
}

sub apply_ocr {
	my ($file, $to_dir) = @_;
	my $tempdir = Path::Tiny->tempdir;
	my $tempfile = $tempdir->child('temp.pdf');

	apply_ocr_file( $file , $tempfile );
	my $new_file = $to_dir->child( $file->basename );
	$tempfile->move($new_file);

	$file->remove;

	return $new_file;
}

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

sub get_rename {
	my ($input_file, $output_dir) = @_;
	# $input_file: Path::Tiny input file
	# $output_dir: Path::Tiny output directory

	my $new_filename = get_title($input_file);
	#say $new_filename;

	my $suffix_num = 1;
	my $probe_file = $output_dir->child( $new_filename . PDF_EXTENSION_W_DOT );
	if( ! -f  $probe_file ) {
		return $probe_file;
	}

	do {
		$probe_file = $output_dir->child( $new_filename . "-$suffix_num" . PDF_EXTENSION_W_DOT );
		$suffix_num++;
	} while( -f  $probe_file );

	return $probe_file;
}

sub apply_rename {
	my ($input_file, $output_dir) = @_;
	# $input_file: Path::Tiny input file
	# $output_dir: Path::Tiny output directory

	my $probe_file = get_rename( $input_file, $output_dir );

	$input_file->move( $probe_file );

	return $probe_file;
}

sub apply_backup {
	my ($input_file, $output_dir) = @_;
	my $new_file = $output_dir->child( $input_file->basename );
	$input_file->move($new_file);

	return $new_file;
}

main;

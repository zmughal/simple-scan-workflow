#!/usr/bin/env perl
# ABSTRACT: 

use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;
use Path::Tiny;
use CLI::Osprey;
use feature 'signatures';

sub main {
	my $pdf_re = qr/\.pdf$/i;
	my $dir_arg = shift @ARGV;
	my $dir = path($dir_arg);

	my $input_dir = $dir->child('input');
	my $ocr_dir = $dir->child('ocr');
	my $rename_dir = $dir->child('ocr');
	my $postprocess_dir = $dir->child('postprocess');
	my $backup_dir = $dir->child('backup');

	$_->mkpath for ($ocr_dir, $rename_dir, $postprocess_dir, $backup_dir);


	run_ocr($input_dir, $ocr_dir);
	run_rename($ocr_dir, $rename_dir);
	run_postprocess($rename_dir, $postprocess_dir);
	run_backup($postprocess_dir, $backup_dir);
}

sub run_ocr($from_dir, $to_dir) { ## no critic
	for my $file ( $from_dir->children( $pdf_re ) ) {
		say "Run OCR on file: $file";
	}
}

sub run_rename($from_dir, $to_dir) { ## no critic
	for my $file ( $from_dir->children( $pdf_re ) ) {
		say "Run rename on file: $file";
	}
}

sub run_postprocess($from_dir, $to_dir) { ## no critic
}

sub run_backup($from_dir, $to_dir) { ## no critic
}

sub apply_ocr {

}

main;

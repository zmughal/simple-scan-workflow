package SSW::Workflow::V1;
# ABSTRACT: Second version of workflow

use Modern::Perl;
use Path::Tiny;
use File::Find::Rule;
use Mu;
use CLI::Osprey;

use IPC::Run qw(start);

use SSW::Daemon::Duckling;
use SSW::Helpers;


sub rule_find_pdf {
	File::Find::Rule->extras({ follow => 1 })
		->file->name( PDF_RE );
}

sub rule_process_pdf {
	my $rule = File::Find::Rule->extras({ follow => 1 });
	$rule->or(
		$rule->new->directory->name('.backup')->prune->discard,

		$rule->file->name( PDF_RE ),
	);

}


# - Any document dropped in Scansnap Home folder should get OCR then be
#   moved to Ready to Move to NAS
# - Once ready to move to NAS, then rename each document and save each
#   document by month and year the document was written in, then move to
#   NAS Inbox folder in which are subfolders named fir each year since
#   1999 each with a subfolders as follows 1.Jan, 2.Feb etc . Any
#   documents older than 2000 save to folder 1999
sub run {
	my ($self) = @_;
	my $dir_arg = shift @ARGV or die "require path as argument";
	my $dir = path($dir_arg)->absolute;

	my $duckling = SSW::Daemon::Duckling->new_with_options;
	$duckling->_daemon->run_command('start');
	sleep 2;

	my $input_dir       = $dir->child('01 input');
	my $ocr_dir         = $dir->child('02 ocr');
	my $rename_dir      = $dir->child('03 rename');

	for my $dir ($input_dir, $ocr_dir, $rename_dir) {
		die "Directory $dir does not exist\n" unless -d $dir;
	}

	while( 1 ) {
		run_ocr($input_dir, $ocr_dir);
		run_rename($ocr_dir, $rename_dir);

		say "Run loop";

		my $h = start [qw(fswatch), qw(-orL), $dir], \my $in, \my $out, \my $err or die "fswatch: $?";
		$h->pump;
		$out = "";
		$h->pump until length $out;
		say $out;
		$h->kill_kill;
	}
};

sub run_ocr {
	my ($from_dir, $to_dir) = @_;
	my @files = map { path($_) } rule_find_pdf()->in( $from_dir );
	for my $file ( @files ) {
		say "Run OCR on file: $file";
		my $new_file = apply_ocr( $file, $to_dir );
		say "\t$file -> $new_file";
	}
}

sub run_rename {
	my ($from_dir, $to_dir) = @_;
	my @files = map { path($_) } rule_find_pdf()->in( $from_dir );
	for my $file ( @files ) {
		say "Run rename on file: $file";
		my $new_file = apply_rename($file, $to_dir);
		say "\t$file -> $new_file";
	}
}

sub apply_ocr {
	my ($file, $to_dir) = @_;
	my $tempdir = Path::Tiny->tempdir;
	my $tempfile = $tempdir->child('temp.pdf');

	apply_ocr_file( $file , $tempfile );
	my $new_file = $to_dir->child( $file->basename );
	$tempfile->copy($new_file);

	$file->remove;

	return $new_file;
}

sub apply_rename {
	my ($input_file, $output_dir) = @_;
	# $input_file: Path::Tiny input file
	# $output_dir: Path::Tiny output directory

	my $probe_file = get_rename( $input_file, $output_dir );

	extract_date( $input_file );

	#$input_file->copy( $probe_file );
	#$input_file->remove;

	return $probe_file;
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

1;

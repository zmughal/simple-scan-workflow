#!/usr/bin/env perl

use utf8;
use FindBin;

use Modern::Perl;
use Path::Tiny;
use Text::Template;

my $dirname = path( $FindBin::Bin );
my $template_file = $dirname->child('DEVONthink-applescript/DEVONthink Pro 2/Scripts/Rename PDF (simple-scan-workflow).applescript.template');
my $template_text = $template_file->slurp_utf8;
my $dirname_abs = $dirname->absolute;

my $template = Text::Template->new(
	TYPE => 'STRING',
	SOURCE => $template_text,
	DELIMITERS => [ "«", "»" ],
);
my $text = $template->fill_in( HASH => {
	ssw_path => "$dirname_abs"
});

my $tempdir = Path::Tiny->tempdir;
my $applescript_file = $tempdir->child(
	$template_file->basename('.template')
);

$applescript_file->spew_utf8( $text );

my $scpt_outpt = $template_file->parent->relative('DEVONthink-applescript')
	->absolute('~/Library/Application Support')->child(
		$template_file->basename('.applescript.template') . '.scpt'
	);
$scpt_outpt->parent->mkpath;

say "Writing to $scpt_outpt";

system("osacompile",
	qw(-l AppleScript),
	qw(-o), $scpt_outpt,
	$applescript_file );

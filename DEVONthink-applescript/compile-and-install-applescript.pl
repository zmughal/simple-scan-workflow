#!/usr/bin/env perl

use utf8;
use FindBin;

use Modern::Perl;
use Path::Tiny;
use Text::Template;
use Dir::Self;

my $dirname = path( __DIR__ );
my $template_file = $dirname->child('DEVONthink Pro 2/Scripts/Rename PDF (simple-scan-workflow).applescript.template');
my $template_text = $template_file->slurp_utf8;
my $ssw_path = $dirname->parent->absolute;

my $template = Text::Template->new(
	TYPE => 'STRING',
	SOURCE => $template_text,
	DELIMITERS => [ "«", "»" ],
);
my $text = $template->fill_in( HASH => {
	ssw_path => "$ssw_path"
});

my $tempdir = Path::Tiny->tempdir;
my $applescript_file = $tempdir->child(
	$template_file->basename('.template')
);

$applescript_file->spew_utf8( $text );

my $scpt_outpt = $template_file->parent->relative( $dirname )
	->absolute('~/Library/Application Support')->child(
		$template_file->basename('.applescript.template') . '.scpt'
	);
$scpt_outpt->parent->mkpath;

say "Writing to $scpt_outpt";

system("osacompile",
	qw(-l AppleScript),
	qw(-o), $scpt_outpt,
	$applescript_file );

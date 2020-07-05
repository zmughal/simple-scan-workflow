#!/usr/bin/env perl
# ABSTRACT: Run OCR and rename on input PDF files

use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;
use autodie qw(:all);
use SSW::Workflow::V0;

sub main {
	SSW::Workflow::V0->run;
}

main;

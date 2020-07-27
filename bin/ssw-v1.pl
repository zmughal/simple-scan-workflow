#!/usr/bin/env perl
# PODNAME: ssw-v1
# ABSTRACT: «description»

use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;
use autodie qw(:all);
use SSW::Command;

sub main {
	SSW::Command->new_with_options->run;
}

main;

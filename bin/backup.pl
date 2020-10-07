#!/usr/bin/env perl
# PODNAME: backup
# ABSTRACT: Run backup from multiple hosts

use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;
use SSW::Backup;

sub main {
	SSW::Backup->new_with_options->run;
}

main;

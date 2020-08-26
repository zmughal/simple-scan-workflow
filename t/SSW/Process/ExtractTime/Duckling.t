#!/usr/bin/env perl

use Test::Most tests => 2;
use lib '.';
use t::SSW::Process::ExtractTime::Duckling;

t::SSW::Process::ExtractTime::Duckling->runtests;

done_testing;

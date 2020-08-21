#!/usr/bin/env perl

use Test::Most;
use lib '.';
use t::SSW::Process::ExtractTime::DucklingFilter;

t::SSW::Process::ExtractTime::DucklingFilter->runtests;

done_testing;

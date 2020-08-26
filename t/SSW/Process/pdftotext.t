#!/usr/bin/env perl

use Test::Most tests => 1;

use Path::Tiny;
use SSW::Process::pdftotext;

subtest "Process pdftotext" => sub {
	plan skip_all => 'Need data path' unless exists $ENV{RENARD_TEST_DATA_PATH};
	my $pdf_file = path( $ENV{RENARD_TEST_DATA_PATH} )->child('PDF/Adobe/pdf_reference_1-7.pdf');

	my $pdftotext = SSW::Process::pdftotext->new(
		input_file => $pdf_file,
		last_page_number => 1,
	);

	$pdftotext->process;

	my $text = $pdftotext->output_text;

	like $text, qr/PDF\sReference/ms, 'Has expected text';
};

done_testing;

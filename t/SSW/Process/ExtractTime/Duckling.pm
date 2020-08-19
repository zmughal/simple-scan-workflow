package t::SSW::Process::ExtractTime::Duckling;
# ABSTRACT: Test class for extracting time

use Test::Most;
use lib 't/lib';
use parent qw(TestDuckling);

use DateTime;
use DateTime::Format::ISO8601;
use v5.26;

use SSW::Process::ExtractTime::Duckling;

sub duckling_data_and_process :Test(setup)  {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There are some dates in here such as January 2nd, 2008. But we
		can also talk about 1/23/2008. Or 3rd of Feb.
		Or maybe the 29th of February.
		EOF

	$self->{data}{text_dates} = [
			'January 2nd, 2008',
			'1/23/2008',
			'3rd of Feb',
			'29th of February',
		];

	$self->{data}{dates_iso8601} = [
			'2008-01-02',
			'2008-01-23',
			'2021-02-03',
			'2024-02-29',
		];

	$self->{data}{reftime} = DateTime->new(
		year => 2020, month => 8, day => 2
	);

	$self->{data}{tz} = 'America/New_York';

	$self->{extracttime_duckling} = SSW::Process::ExtractTime::Duckling->new(
		input_text => $self->{data}{text},
		input_args => {
			reftime => $self->{data}{reftime},
			tz => $self->{data}{tz},
		}
	);

	$self->{extracttime_duckling}->process;
}

sub check :Test(2) {
	my ($self) = @_;

	my $data = $self->{extracttime_duckling}->output_data;

	my @body_text = map { $_->{body}  } @$data;
	#use XXX; XXX @body_text;
	cmp_deeply \@body_text, [
		map { re(qr/\Q$_\E/) } @{ $self->{data}{text_dates} }
	], 'extracted text';

	my @values = map {
		my $dt = DateTime::Format::ISO8601->parse_datetime( $_->{value}{value} );
		$dt->strftime('%F');
	} @$data;

	cmp_deeply \@values, $self->{data}{dates_iso8601}, 'values';
}

1;

package t::SSW::Process::ExtractTime::DucklingFilter;
# ABSTRACT: Test class for filtering output of Duckling

use Test::Most tests => 8;
use lib 't/lib';
use parent qw(TestDuckling);

use SSW::Process::ExtractTime::DucklingFilter;

sub check_specific_date :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There are some dates in here such as January 2nd, 2008. But we
		can also talk about 1/23/2008. Or 3rd of Feb.
		Or maybe the 29th of February.
		EOF

	$self->{data}{expect} = '2008-01-02';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_year :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There are some dates in here such as January 2nd. But we
		can also talk about 1/23. Or 3rd of Feb.
		Or maybe the 29th of February.
		EOF

	$self->{data}{expect} = 'YYYY-01-02';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_year_month :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		Some time on the second.
		EOF

	$self->{data}{expect} = 'YYYY-MM-02';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_month :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		Some time on the second in 2010.
		EOF

	$self->{data}{expect} = '2010-MM-02';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_day :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There are some months in here such as January 2009. But we can
		also continue. Or Feb 2009.
		Or maybe March 2009.
		EOF

	$self->{data}{expect} = '2009-01-DD';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_month_day :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There are some bugs to fix in 2000.
		EOF

	$self->{data}{expect} = '2000-MM-DD';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_missing_any_dt_at_all :Test(1) {
	my ($self) = @_;

	$self->{data}{text} = <<~'EOF';
		There is nothing in here. You get nothing!
		Nope, not even on this line.
		EOF

	$self->{data}{expect} = 'YYYY-MM-DD';

	my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
		input_text => $self->{data}{text},
	);

	$filter->process;

	is $filter->output_data, $self->{data}{expect};
}

sub check_interval :Test(1) {
	my ($self) = @_;

	subtest "Intervals" => sub {
		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed from 09/20/1995 to 09/22/1995.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, '1995-09-20', 'specific bounded interval';

		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed from 09/20 to 09/22.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, 'YYYY-09-20', 'bounded interval missing year';

		is do {
			note <<~EOF;
			Generates an unspecific "interval" type (missing year)
			and a specific "value" type.  The year does not
			propagate to start of interval.
			EOF
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed from 09/20 to 09/22/1995.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, '1995-09-22', 'bounded interval but also specific end date';

		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed from 09/20/1995.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, '1995-09-20', 'specific unbounded interval (from)';

		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed until 09/22/1995.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, '1995-09-22', 'specific unbounded interval (until)';

		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed from 09/20.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, 'YYYY-09-20', 'unbounded interval missing year (from)';

		is do {
			my $filter = SSW::Process::ExtractTime::DucklingFilter->new(
				input_text => <<~'EOF'
					The office is closed until 09/22.
					EOF
			);
			$filter->process;
			$filter->output_data;
		}, 'YYYY-09-22', 'unbounded interval missing year (until)';
	};
}

1;

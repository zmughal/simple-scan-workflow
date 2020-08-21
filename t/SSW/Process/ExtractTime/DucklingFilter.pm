package t::SSW::Process::ExtractTime::DucklingFilter;
# ABSTRACT: Test class for filtering output of Duckling

use Test::Most tests => 7;
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

1;

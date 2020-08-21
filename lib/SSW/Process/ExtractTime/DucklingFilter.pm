package SSW::Process::ExtractTime::DucklingFilter;
# ABSTRACT: Use Duckling output to determine reference time

use Modern::Perl;
use Mu;
use DateTime;
use DateTime::Format::ISO8601;
use List::Util v1.55 qw(uniqint);

use SSW::Process::ExtractTime::Duckling;

ro 'input_text';

ro 'input_args',
	required => 0,
	default => sub { +{} };

rw 'output_data', required => 0;

sub _get_data_with_reftime {
	my ($self, $reftime) = @_;

	my $process = SSW::Process::ExtractTime::Duckling->new(
		input_text => $self->input_text,
		input_args => {
			%{ $self->input_args },
			reftime => $reftime,
		},
	);
	$process->process;
	my $data = $process->output_data;

	my @times = grep { $_->{dim} eq 'time' } @$data;

	\@times;
}

use constant UNKNOWN_YEAR  => 'YYYY';
use constant UNKNOWN_MONTH => 'MM';
use constant UNKNOWN_DAY   => 'DD';

sub _check_specificity {
	my ($self, $reftime_dt) = @_;
	my $years_duration = DateTime::Duration->new( years => 4 );
	my $months_duration = DateTime::Duration->new( months => 1 );
	if( ($reftime_dt - $months_duration)->year != $reftime_dt->year ) {
		$months_duration->inverse;
	}
	my $days_duration = DateTime::Duration->new( days => 1 );
	if( ($reftime_dt - $days_duration)->month != $reftime_dt->month ) {
		$days_duration->inverse;
	}

	my $r_times = $self->_get_data_with_reftime($reftime_dt);
	my $y_times = $self->_get_data_with_reftime($reftime_dt - $years_duration  );
	my $m_times = $self->_get_data_with_reftime($reftime_dt - $months_duration );
	my $d_times = $self->_get_data_with_reftime($reftime_dt - $days_duration   );

	sub _get_value_container {
		my ($input_value) = @_;
		my $container;
		if( $input_value->{type} eq 'interval' ) {
			$container = exists $input_value->{from}
				? $input_value->{from}
				: $input_value->{to}
		} elsif( $input_value->{type} eq 'value' ) {
			$container = $input_value;
		} else {
			die "Unknown type @{[ $input_value->{type} ]}";
		}

		$container;
	}

	sub _parse_to_dt {
		my ($time_data) = @_;
		[ map {
			DateTime::Format::ISO8601->parse_datetime(
				_get_value_container($_)->{value},
			)
		} @{ $time_data->{value}{values} } ];
	}

	#use DDP; p $r_times;
	for my $idx (0..@$r_times-1) {
		my $current = $r_times->[$idx];
		my $dts = _parse_to_dt($current);

		if( @$dts == 1 ) {
			my $first_value = _get_value_container($current->{value}{values}[0]);
			if( $first_value->{grain} eq 'year' ) {
				$current->{out} = [
					$dts->[0]->year,
					UNKNOWN_MONTH,
					UNKNOWN_DAY,
				];
			} elsif( $first_value->{grain} eq 'month' ) {
				$current->{out} = [
					$dts->[0]->year,
					sprintf("%02d", $dts->[0]->month),
					UNKNOWN_DAY,
				];
			} else {
				# ( $first_value->{grain} eq 'day' )
				$current->{out} = [
					$dts->[0]->year,
					sprintf("%02d", $dts->[0]->month),
					sprintf("%02d", $dts->[0]->day),
				];
			}
		} else {

			sub _check_part {
				my ($dts, $p_times, $part_attr, $unknown, $format) = @_;

				my @r_time_p = map { $_->$part_attr } @$dts;
				my @p_time_p = map { $_->$part_attr } @{ _parse_to_dt( $p_times ) };
				if( uniqint(@r_time_p) == 1
					&& uniqint(@p_time_p) == 1
					&& $r_time_p[0] == $p_time_p[0] ) {
					# all the $part_attr in the reftime are
					# same 1 == uniqint and are the same # year as p_times
					# then the specificity is known
					return sprintf($format,$r_time_p[0]);
				} else {
					return $unknown;
				}

			}

			my $year_part  = _check_part($dts, $y_times->[$idx], 'year' , UNKNOWN_YEAR , "%d"   );
			my $month_part = _check_part($dts, $m_times->[$idx], 'month', UNKNOWN_MONTH, "%02d" );
			my $day_part   = _check_part($dts, $d_times->[$idx], 'day'  , UNKNOWN_DAY  , "%02d" );

			$current->{out} = [
				$year_part,
				$month_part,
				$day_part,
			];
		}
	}

	$r_times;
}

sub process {
	my ($self) = @_;
	my $reftime_dt = DateTime->now;

	if( exists $self->input_args->{reftime} ) {
		$reftime_dt = SSW::Process::ExtractTime::Duckling->reftime_to_datetime(
			$self->input_args->{reftime}
		);
	}

	my $data = $self->_check_specificity( $reftime_dt );

	my $output = 'YYYY-MM-DD';

	my @sorted = sort map {
		join "-", @$_
	} map { $_->{out} } @$data;

	if( @sorted ) {
		$output = $sorted[0];
	}

	$self->output_data( $output );
}

1;

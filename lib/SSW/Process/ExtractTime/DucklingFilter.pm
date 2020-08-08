package SSW::Process::ExtractTime::DucklingFilter;
# ABSTRACT: Choose date from Duckling output

use Modern::Perl;
use Mu;

ro 'input_data';

ro 'output_data';

sub process {
	my ($self) = @_;
	...;

	my $js = $self->input_data;
	if( 0 ) {
	my @times = grep { $_->{dim} eq 'time' } @$js;
	say "Times: @{[ scalar @times ]}/@{[ scalar @$js ]}";

	use warnings FATAL => 'uninitialized';
	for my $time (@times) {
		my $body = $time->{body};
		my $value;

		my $type = $time->{value}{type};
		if( $type eq 'interval' ) {
			my $interval = exists $time->{value}{from} ? $time->{value}{from} : $time->{value}{to};
			$value = $interval->{value};
		} elsif( $type eq 'value' ) {
			$value = $time->{value}{value};
		} else {
			warn "Unknown type $type";
		}
		say "$body | $value";
	}
	use DDP; p $js;
	}
}

1;

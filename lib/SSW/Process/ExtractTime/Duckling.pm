package SSW::Process::ExtractTime::Duckling;
# ABSTRACT: Extract time from text

use Modern::Perl;
use Mu;

use LWP::UserAgent;
use JSON::MaybeXS;

ro 'input_text';

ro 'input_args',
	required => 0,
	default => sub { +{} };

rw 'output_data', required => 0;

sub process {
	my ($self) = @_;

	my $text = $self->input_text;

	my $ua = LWP::UserAgent->new;

	my %input_args = %{ $self->input_args };
	if( exists $input_args{reftime}
		&& ref $input_args{reftime}
		&& $input_args{reftime}->isa('DateTime')
		) {
		$input_args{reftime} = $self->datetime_to_reftime($input_args{reftime});
	}

	#my @post_args = ( "text", "lang", "dims", "tz", "locale", "reftime", "latent", );
	my $response = $ua->post( "http://0.0.0.0:@{[ SSW::Daemon::Duckling->PORT ]}/parse",
		Content => {
			locale => 'en_US',
			#dims => encode_json(['time']),
			text => $text,
			%input_args,
		}
	);
	my $response_data = decode_json( $response->content );

	$self->output_data( $response_data );
}

use constant S_TO_MS => 1000;
use constant MS_TO_S => 1 / S_TO_MS;

sub datetime_to_reftime {
	my ($class, $datetime) = @_;
	$datetime->epoch * S_TO_MS;
}

sub reftime_to_datetime {
	my ($class, $reftime) = @_;
	DateTime->from_epoch( epoch => $reftime * MS_TO_S );
}

1;

package SSW::Mirror::LFTP;
# ABSTRACT: An LFTP mirror

use Modern::Perl;
use Mu;
use ShellQuote::Any;
use JSON::MaybeXS;

use SSW::Connection::LocalFS;

use constant LFTP_BIN => 'lftp';

ro source_connection =>;

ro destination_connection => ;

ro source_path => ;

ro destination_path => ;

lazy lftp_command => sub {
	my ($self) = @_;

	my $src_connection = $self->source_connection;

	my $dst_connection = $self->destination_connection;

	my @ssh_connections = grep { $_->isa('SSW::Connection::SSH') } ($src_connection, $dst_connection);
	if( 2 == @ssh_connections ) {
		die "Can not mirror two SSH connections";
	} elsif( 1 == @ssh_connections ) {
		if( $src_connection->isa('SSW::Connection::SSH' ) ) {
			system( qw(ssh-add), $src_connection->identity_file );
			return [
				@{ $src_connection->ssh_command },
				qw(-t),

				"PATH=/usr/local/bin:\$PATH; "
				.
				shell_quote(
					SSW::Mirror::LFTP->new(
						source_connection => SSW::Connection::LocalFS->new(
							mount_point => '/',
						),
						destination_connection => $self->destination_connection,
						source_path => $src_connection->normalize_path($self->source_path),
						destination_path => $self->destination_path . "/" ,
					)->lftp_command
				),
			],
		} else {
			...
		}
	} else {
		if( $src_connection->isa('SSW::Connection::LocalFS') && $dst_connection->isa('SSW::Connection::FTP') ) {
			[
				LFTP_BIN,
				#$dst_connection->ftp_uri,
				qw(-e),
				join " ; ", (
					$self->get_lftp_open_command( $dst_connection ),
					shell_quote([
						qw(mirror -v -R -c),
						$self->source_path,
						$self->destination_path,
					]),
					"exit",
				)
			]
		} elsif( $src_connection->isa('SSW::Connection::FTP') && $src_connection->isa('SSW::Connection::LocalFS') ) {
			...
		}
	}
};

sub get_lftp_open_command {
	my ($self, $connection) = @_;
	my $machine = $connection->lookup_netrc;
	return qq|open --password @{[ $machine->password ]} @{[ $connection->ftp_uri ]}|;
}

sub mirror {
	my ($self) = @_;
	say "==\n", JSON->new->allow_nonref->convert_blessed->encode( $self->lftp_command );
	0 == system(
		@{ $self->lftp_command }
	) or die "Command failed";
}


1;

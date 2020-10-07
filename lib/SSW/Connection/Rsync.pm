package SSW::Connection::Rsync;
# ABSTRACT: An Rsync connection

use Mu;
use File::Which;
use ShellQuote::Any;
use Net::EmptyPort qw(empty_port);

use constant RSYNC_BIN => 'rsync';

use constant RSYNC_OPTS => qw(-avzP --stats);

ro source_connection =>;

ro destination_connection => ;

ro source_path => ;

ro destination_path => ;

lazy rsync_command => sub {
	my ($self) = @_;


	my $src_connection = $self->source_connection;
	$src_connection = $self->try_connection_to_localfs($src_connection);

	my $dst_connection = $self->destination_connection;
	$dst_connection = $self->try_connection_to_localfs($dst_connection);

	my @ssh_connections = grep { $_->isa('SSW::Connection::SSH') } ($src_connection, $dst_connection);
	if( 2 == @ssh_connections ) {
		if( $src_connection->host ne $dst_connection->host ) {
			my $free_port = empty_port();

			my $dst_hostport = join ":", map { $dst_connection->$_ } qw(host port);

			my @tunnel = ( qw(-R), "localhost:$free_port:$dst_hostport" );

			system( qw(ssh-add), $src_connection->identity_file );

			my $tunnel_cmd = sub {
				my (@cmd) = @_;
				return (
					qw(ssh),
					qw(-t),
					qw(-A),
					@tunnel,

					@{ $src_connection->ssh_options },

					$src_connection->host,

					@cmd,
				);
			};

			my @ssh_on_src_to_dst_through_tunnel_opts = (
				qw(-A),
				qw(-o StrictHostKeyChecking=no),
				qw(-p), $free_port,
				qw(-l), $dst_connection->login_name,
			);

			0 == system( $tunnel_cmd->(
				$dst_connection->SSH_BIN,
				@ssh_on_src_to_dst_through_tunnel_opts,
				qw(localhost),

				shell_quote([ qw(echo PASSED)] ),
			) ) or die "Could not create tunneled SSH connection through localhost\n";

			return [
				$tunnel_cmd->(
					RSYNC_BIN,
					RSYNC_OPTS,

					(
						qw(-e), shell_quote( [
							$dst_connection->SSH_BIN,
							@ssh_on_src_to_dst_through_tunnel_opts,
						] ),
					),

					$src_connection->normalize_path( $self->source_path ),

					$dst_connection->rsync_arg( $self->destination_path )
						=~ s/^\Q@{[ $dst_connection->host ]}:\E/localhost:/r,
				)
			];
		} else {
			return [
				@{ $src_connection->ssh_command },

				RSYNC_BIN,
				RSYNC_OPTS,

				$src_connection->normalize_path($self->source_path),

				$dst_connection->normalize_path($self->destination_path),
			];
		}
	} else {
		return [
			RSYNC_BIN,
			RSYNC_OPTS,

			1 == @ssh_connections ? (
				qw(-e), shell_quote( [
					$ssh_connections[0]->SSH_BIN,
					@{ $ssh_connections[0]->ssh_options },
				] ),
			) : (),

			$src_connection->rsync_arg($self->source_path),

			$dst_connection->rsync_arg($self->destination_path),
		];

	}
};

sub try_connection_to_localfs {
	my ($self, $connection) = @_;

	if( $connection->isa('SSW::Connection::FTP' ) ) {
		return $connection->to_localfs_connection;
	}

	$connection;
}


after new => sub {
	which( RSYNC_BIN ) or die "Missing executable @{[ RSYNC_BIN ]}\n";
};

1;

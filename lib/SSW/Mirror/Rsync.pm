package SSW::Mirror::Rsync;
# ABSTRACT: An Rsync mirror

use Modern::Perl;
use Mu;
use JSON::MaybeXS;
use boolean;
use File::Which;
use ShellQuote::Any;
use Net::EmptyPort qw(empty_port);
use Path::Tiny;
use Log::Any qw($log);

use constant RSYNC_BIN => 'rsync';

use constant RSYNC_OPTS => qw(-a -vzP --stats);

ro source_connection =>;

ro destination_connection => ;

ro source_path => ;

ro destination_path => ;

lazy rsync_command => sub {
	my ($self) = @_;

	die "Destination does not support utime(2)" unless $self->supports_utime( $self->destination_connection );

	my $src_connection = $self->source_connection;
	$src_connection = $self->try_connection_to_localfs($src_connection);

	my $dst_connection = $self->destination_connection;
	$dst_connection = $self->try_connection_to_localfs($dst_connection);

	for my $connection ($src_connection, $dst_connection) {
		die "Connection not rsyncable" unless $connection->can('rsync_arg');
	}

	my @ssh_connections = grep { $_->isa('SSW::Connection::SSH') } ($src_connection, $dst_connection);
	if( 2 == @ssh_connections ) {
		if( $src_connection->host ne $dst_connection->host ) {
			# idea for rsync mirroring over SSH:
			# <https://unix.stackexchange.com/questions/183504/how-to-rsync-files-between-two-remotes/510262#510262>
			my $free_port = empty_port();

			my $dst_hostport = join ":", map { $dst_connection->$_ } qw(host port);

			my @tunnel = ( qw(-R), "localhost:$free_port:$dst_hostport" );

			system( qw(ssh-add), $src_connection->identity_file );

			my $tunnel_cmd = sub {
				my (@cmd) = @_;
				return (
					$src_connection->SSH_BIN,
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

			$log->info("ssh tunnel 'rsync src tunnel-dst'");
			return [
				$tunnel_cmd->(
					RSYNC_BIN,
					RSYNC_OPTS,

					(
						qw(-e), shell_quote([ shell_quote( [
							$dst_connection->SSH_BIN,
							@ssh_on_src_to_dst_through_tunnel_opts,
						] ) ] ),
					),

					shell_quote( [ $src_connection->normalize_path( $self->source_path ) ] ),

					shell_quote([
					$dst_connection->rsync_arg( $self->destination_path )
						=~ s/^\Q@{[ $dst_connection->host ]}:\E/localhost:/r,
					])
				)
			];
		} else {
			$log->info( "ssh 'rsync src dst'");
			return [
				@{ $src_connection->ssh_command },

				shell_quote( [
				RSYNC_BIN,
				RSYNC_OPTS,

				$src_connection->normalize_path($self->source_path),

				$dst_connection->normalize_path($self->destination_path),
				] )
			];
		}
	} else {
		my $dst_not_local = ! $self->destination_connection->isa('SSW::Connection::LocalFS');
		my $dir = path("~/.tmp-for-backup");
		$dir->mkpath;
		my $tempdir = Path::Tiny->tempdir( DIR => $dir );

		$log->info("rsync src dst");
		return [
			RSYNC_BIN,
			RSYNC_OPTS,

			# to avoid "rsync: mkstemp failed: Permission denied" error
			$dst_not_local ? ( qw(-T), $tempdir ) : (),

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

sub supports_utime {
	my ($self, $connection) = @_;

	if( $connection->isa('SSW::Connection::SSH' ) ) {
		return true;
	} elsif( $connection->isa('SSW::Connection::FTP::CurlFtpFS') ) {
		# CurlFtpFS does not support utime. Silently fails
		# <https://fossies.org/dox/curlftpfs-0.9.2/ftpfs_8c_source.html#l00992>.
		return false;
	}

	return false;
}


sub try_connection_to_localfs {
	my ($self, $connection) = @_;

	if( $connection->isa('SSW::Connection::FTP::CurlFtpFS' ) ) {
		return $connection->to_localfs_connection;
	}

	$connection;
}

sub mirror {
	my ($self) = @_;
	#use DDP; p $rsync->rsync_command;
	$log->info("Trying @{[ ref $self ]} mirror for: "
		. $self->stringify_connection_path($self->source_connection, $self->source_path)
		. " => "
		. $self->stringify_connection_path($self->destination_connection, $self->destination_path)
	) if $log->is_info;
	$log->debug(
		"Command: ".
		JSON->new->allow_nonref->convert_blessed->encode( $self->rsync_command )
	) if $log->is_debug;
	0 == system(
		@{ $self->rsync_command }
	) or die "Command failed";
}

after new => sub {
	which( RSYNC_BIN ) or die "Missing executable @{[ RSYNC_BIN ]}\n";
};

sub stringify_connection_path {
	my ($self, $connection, $path) = @_;
	return "@{[ $connection->host ]}:( @{[ $path ]} )";
}

1;

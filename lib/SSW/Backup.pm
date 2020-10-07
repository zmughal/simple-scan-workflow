package SSW::Backup;
# ABSTRACT: Backup

use Modern::Perl;
use boolean;
use Mu;
use CLI::Osprey;
use YAML::XS ();
use JSON::MaybeXS;
use Path::Tiny;
use ShellQuote::Any;

use SSW::Connection::SSH;
use SSW::Connection::Rsync;
use SSW::Connection::FTP;

option config_path => (
	is => 'ro',
	required => 1,
	format => 's',
);

option check_host_path => (
	is => 'ro',
	required => 0,
	# format => None, ->  boolean
	default => sub { true },
	negatable => true,
);

lazy config => sub {
	my ($self) = @_;
	YAML::XS::LoadFile( $self->config_path );
};

lazy host_to_connections => sub {
	my ($self) = @_;

	my $host_to_connections;
	for my $host (@{ $self->config->{hosts} }) {
		my $hostname = $host->{host};
		if( exists $host->{ssh} ) {
			if( exists $host->{ssh}{identity_file} ) {
				# identity_file is relative to config_path
				$host->{ssh}{identity_file} = path(
					$host->{ssh}{identity_file}
				)->absolute(
					path( $self->config_path )->parent
				);
			}
			$host_to_connections->{$hostname}{ssh} = SSW::Connection::SSH->new(
				host => $hostname,
				%{ $host->{ssh} },
			);
			$host_to_connections->{$hostname}{ssh}->ssh_command;
		}

		if( exists $host->{ftp} ) {
			$host_to_connections->{$hostname}{ftp} = SSW::Connection::FTP->new(
				host => $hostname,
				%{ $host->{ftp} },
			);
		}
	}

	$host_to_connections;
};

sub run {
	my ($self) = @_;
	use DDP; p $self->config;

	if( $self->check_host_path ) {
		for my $destination (@{ $self->config->{destinations} }) {
			$self->check_connection_host_path($destination);
		}

		for my $source (@{ $self->config->{sources} }) {
			$self->check_connection_host_path($source);
		}
	}

	for my $source (@{ $self->config->{sources} }) {
		for my $destination (@{ $self->config->{destinations} }) {
			my $rsync = SSW::Connection::Rsync->new(
				source_connection => $self->select_preferred_connection(
					$self->host_to_connections->{$source->{host}},
				),
				destination_connection => $self->select_preferred_connection(
					$self->host_to_connections->{$destination->{host}},
				),
				source_path => $source->{path},
				destination_path => $destination->{path},
			);
			#use DDP; p $rsync->rsync_command;
			say "==\n", JSON->new->allow_nonref->convert_blessed->encode( $rsync->rsync_command );
			0 == system(
				@{ $rsync->rsync_command }
			) or die "Command failed";
		}
	}
}

sub check_connection_host_path {
	my ($self, $hostpath) = @_;

	exists $self->host_to_connections->{$hostpath->{host}}
		or die "Host connection not defined: @{[ $hostpath->{host} ]}\n";
	my $connections = $self->host_to_connections->{$hostpath->{host}};
	my $path = $hostpath->{path};
	$self->check_connection_remote_directory( $connections, $path);
}

sub check_connection_remote_directory {
	my ($self, $connections, $path) = @_;

	if( exists $connections->{ssh} ) {
		$connections->{ssh}->check_remote_directory( $path );
	} elsif( exists $connections->{ftp} ) {
		$connections->{ftp}->check_remote_directory( $path );
	}
}

sub select_preferred_connection {
	my ($self, $connections) = @_;

	for my $type (qw(ssh ftp)) {
		next unless exists $connections->{$type};
		return $connections->{$type}
	}

	undef;
}

sub rsync_arg {
	my ($self, $connections, $path) = @_;

	my $arg = $self->select_preferred_connection($connections)
		->rsync_arg( $path );

	return shell_quote( [ $arg ] );
}

1;

package SSW::Connection::SSH;
# ABSTRACT: An SSH connection

use Mu;
use File::Which;
use ShellQuote::Any;

use constant SSH_BIN => 'ssh';

ro host =>;

ro login_name => ;

has port => (
	is => 'ro',
	default => sub { 22 },
	predicate => 1,
);

has identity_file => (
	is => 'ro',
	predicate => 1,
);

lazy ssh_command => sub {
	my ($self) = @_;
	return [
		SSH_BIN,

		@{ $self->ssh_options },

		$self->host,
	];
};

lazy ssh_options => sub {
	my ($self) = @_;
	return [
		( $self->has_port ? ( qw(-p), $self->port ) : () ),

		( $self->has_identity_file ? ( qw(-i), $self->identity_file ) : () ),

		( qw(-l), $self->login_name  ),
	];
};

sub check_remote_directory {
	my ($self, $path) = @_;

	$path = $self->normalize_path($path);

	my $quoted_path = shell_quote( [ $path ] );
	0 == system(
		@{ $self->ssh_command },
		qq{[ -d $quoted_path ] && [ -n "\$( ls -A $quoted_path )" ]}
	) or die <<~EOF;
	Remote directory does not exist: $path

	NOTE: Add a .keep file if creating a new destination:
	  ssh @{[ $self->host ]} touch $quoted_path/.keep
	EOF
}

after new => sub {
	which( SSH_BIN ) or die "Missing executable @{[ SSH_BIN ]}\n";
};

sub is_windows_path {
	my ($self, $path) = @_;
	$path =~ m,^[A-Z]:[\\/],;
}

sub convert_path_windows_to_cygwin {
	my ($self, $path) = @_;

	# Windows to Cygwin-style path
	return $path
		=~ s,^([A-Z]):,/$1,r
		=~ s,\\,/,gr
}

sub normalize_path {
	my ($self, $path) = @_;

	if( $self->is_windows_path($path) ) {
		return $self->convert_path_windows_to_cygwin($path);
	}

	return $path;
}

sub rsync_arg {
	my ($self, $path) = @_;
	return "@{[ $self->host ]}:@{[ $self->normalize_path($path) ]}";
}

1;

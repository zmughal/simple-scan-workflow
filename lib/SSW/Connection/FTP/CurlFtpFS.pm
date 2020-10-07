package SSW::Connection::FTP::CurlFtpFS;
# ABSTRACT: An FTP connection via Curlftpfs

use Mu;
use File::Which;
use Net::Netrc;
use Net::FTP;
use Path::Tiny;
use Sys::Filesystem ();
use List::AllUtils qw(first);

use SSW::Connection::LocalFS;

use constant CURLFTPFS_BIN => 'curlftpfs';

ro host => ;

ro login_name => ;

ro mount_point => ;

lazy curlftpfs_command => sub {
	my ($self) = @_;
	Net::Netrc->lookup( $self->host, $self->login_name )
		or die "FTP account not in .netrc: @{[ $self->login_name ]}\@@{[ $self->host ]}\n";

	return [
		CURLFTPFS_BIN,
		$self->ftp_uri,
		path($self->mount_point),
	];
};

lazy ftp_uri => sub {
	my ($self) = @_;

	"ftp://@{[ $self->login_name ]}\@@{[ $self->host ]}/",
};

sub check_remote_directory {
	my ($self, $path) = @_;
	# NOTE:
	# create the remote directory if creating a new destination
	#   lftp $host -e 'mkdir $path'
	my $ftp = Net::FTP->new( $self->host )
		or die "Can not connect to @{[ $self->host ]}\n";
	$ftp->login( $self->login_name )
		or die "Can not login: @{[ $ftp->message ]}";

	$ftp->cwd($path)
		or die <<~EOF;
	Remote directory does not exist: $path

	NOTE: Create the remote directory if creating a new destination:
	  lftp @{[ $self->host ]} -e 'mkdir $path'
EOF
}

sub mount {
	my ($self) = @_;

	# Check mount point
	my $fs = Sys::Filesystem->new;

	my $mp_realpath = path($self->mount_point)->realpath;
	my $fs_on_mp = first { path($_)->realpath eq $mp_realpath }
		$fs->filesystems( mounted => 1 );

	if( $fs_on_mp ) {
		if( $fs->device($fs_on_mp) eq "curlftpfs#@{[ $self->ftp_uri ]}" ) {
			return;
		} else {
			die "Unexpected filesystem on mount point $mp_realpath\n";
		}
	}

	my $mount_point = path($self->mount_point);
	$mount_point->mkpath;

	0 == system(
		@{ $self->curlftpfs_command }
	) or die "Could not mount curlftpfs\n";
}

sub to_localfs_connection {
	my ($self) = @_;
	$self->mount;
	return SSW::Connection::LocalFS->new(
		mount_point => $self->mount_point,
	);
}

sub rsync_arg {
	my ($self, $path) = @_;
	$self->to_localfs_connection->rsync_arg( $path );
}

after new => sub {
	which( CURLFTPFS_BIN ) or die "Missing executable @{[ CURLFTPFS_BIN ]}\n";
};

1;

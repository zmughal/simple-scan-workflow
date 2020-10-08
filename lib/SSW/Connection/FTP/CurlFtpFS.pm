package SSW::Connection::FTP::CurlFtpFS;
# ABSTRACT: An FTP connection via Curlftpfs

use Mu;
use File::Which;
use Path::Tiny;
use Sys::Filesystem ();
use List::AllUtils qw(first);

use SSW::Connection::LocalFS;

extends qw(SSW::Connection::FTP);

use constant CURLFTPFS_BIN => 'curlftpfs';

ro mount_point => ;

lazy curlftpfs_command => sub {
	my ($self) = @_;
	$self->lookup_netrc;

	return [
		CURLFTPFS_BIN,
		$self->ftp_uri,
		path($self->mount_point),
	];
};

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

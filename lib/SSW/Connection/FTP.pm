package SSW::Connection::FTP;
# ABSTRACT: An FTP connection

use Mu;
use Net::FTP;
use Net::Netrc;

ro host => ;

ro login_name => ;

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

sub lookup_netrc {
	my ($self) = @_;
	Net::Netrc->lookup( $self->host, $self->login_name )
		or die "FTP account not in .netrc: @{[ $self->login_name ]}\@@{[ $self->host ]}\n";
}

1;

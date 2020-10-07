package SSW::Connection::LocalFS;
# ABSTRACT: A filesystem at a mount point

use Mu;
use Path::Tiny;

ro mount_point =>;

sub rsync_arg {
	my ($self, $path) = @_;
	return path($self->mount_point)->child($path);
}

1;

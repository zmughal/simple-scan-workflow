package SSW::Daemon::WatcherV1;
# ABSTRACT: Daemon for running workflow V1

use Modern::Perl;
use Mu;
use CLI::Osprey;

option directory => (
	is => 'ro',
	format => 's',
	required => 1,
);

lazy _daemon => sub {
	my ($self) = @_;

	Daemon::Control->new(
		name        => "SSW-Watcher",
		lsb_start   => '$syslog $remote_fs',
		lsb_stop    => '$syslog',
		lsb_sdesc   => 'simple-scan-workflow watcher',
		lsb_desc    => 'Watcher for file events',

		program      => $^X,
		program_args => [ $0, qw(workflow), $self->directory ],

		pid_file    => '/tmp/ssw-watcher.pid',
		stderr_file => '/tmp/ssw-watcher.out',
		stdout_file => '/tmp/ssw-watcher.out',

		fork        => 2,
	);
};

with qw(SSW::Role::Daemonable);

1;

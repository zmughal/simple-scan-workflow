package SSW::Daemon::Duckling;
# ABSTRACT: «TODO»

use Modern::Perl;
use Mu;
use CLI::Osprey;

use Daemon::Control;
use Path::Tiny;
use File::Find::Rule;
use FindBin::libs qw( export scalar base=vendor );

lazy _daemon => sub {
	Daemon::Control->new(
		name        => "Duckling",
		lsb_start   => '$syslog $remote_fs',
		lsb_stop    => '$syslog',
		lsb_sdesc   => 'Duckling text parsing service',
		lsb_desc    => 'Controls the Duckling text parsing HTTP service',

		program      => get_duckling_path(),

		pid_file    => '/tmp/ssw-duckling.pid',
		stderr_file => '/tmp/ssw-duckling.out',
		stdout_file => '/tmp/ssw-duckling.out',

		fork        => 2,
	);
};

sub get_duckling_path {
	my $rule = File::Find::Rule
		->directory
		->name( 'bin' );
	my ($bin) = $rule->in(
		path($vendor)->child('duckling/.stack-work')->realpath
	);

	return path($bin)->child('duckling-example-exe' );
}

subcommand 'path' => sub {
	say get_duckling_path();
};

with qw(SSW::Role::Daemonable);

1;

package TestDuckling;
# ABSTRACT: Duckling setup and teardown

use strict;
use warnings;
use parent qw(Test::Class);

use Net::EmptyPort qw(wait_port);
use Time::HiRes qw(usleep);

use SSW::Daemon::Duckling;

sub start_duckling : Test(startup) {
	my ($self) = @_;

	my $duckling_daemon
		= $self->{duckling}{daemon}
		= SSW::Daemon::Duckling->new_with_options;
	$duckling_daemon->_daemon->scan_name(1);
	$self->{duckling}{do_shutdown} = 0;

	unless( $duckling_daemon->_daemon->pid
		&& $duckling_daemon->_daemon->pid_running ) {

		$duckling_daemon->_daemon->run_command('start');
		if( !wait_port( { port => SSW::Daemon::Duckling->PORT, } ) ) {
			die "Port not available";
		}
		usleep 2e5;
		unless( $duckling_daemon->_daemon->pid_running ) {
			die "Could not start daemon";
		}
		$self->{duckling}{do_shutdown} = 1;
	}
}

sub stop_duckling : Test(shutdown) {
	my ($self) = @_;

	if( $self->{duckling}{do_shutdown} ) {
		$self->{duckling}{daemon}
			->_daemon->run_command('stop');
	}
}

1;

#!/usr/bin/env perl

use Test::Most tests => 1;
use Test::SetupTeardown;
use Net::EmptyPort qw(wait_port);
use Time::HiRes qw(usleep);
use DateTime;
use v5.26;

use SSW::Daemon::Duckling;
use SSW::Process::ExtractTime::Duckling;

my $duckling_daemon = SSW::Daemon::Duckling->new_with_options;
$duckling_daemon->_daemon->scan_name(1);
my $do_shutdown = 0;
sub begin {
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
		$do_shutdown = 1;
	}
}

sub end {
	if( $do_shutdown ) {
		$duckling_daemon->_daemon->run_command('stop');
	}
}

my $environment = Test::SetupTeardown->new( begin => \&begin, end => \&end );

$environment->run_test("Process extract time via Duckling" => sub {
	TODO: {
		local $TODO = 'write test';

		my $text = <<~'EOF';
		There are some dates in here such as January 2nd, 2008. But we
		can also talk about 1/23/2008. Or 3rd of Feb.
		Or maybe the 29th of February.
		EOF

		my $duckling = SSW::Process::ExtractTime::Duckling->new(
			input_text => $text,
			input_args => {
				reftime => DateTime->new(
					year => 2020, month => 8, day => 2
				)->epoch * 1000,
			}
		);

		$duckling->process;

		use Data::Dumper;
		diag Dumper($duckling->output_data);

		fail;
	}
});

done_testing;

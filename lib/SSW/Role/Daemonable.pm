package SSW::Role::Daemonable;
# ABSTRACT: Role for controlling daemons

use Moo::Role;
use CLI::Osprey;
use Log::Any qw($log);

requires '_daemon';

for my $cmd ( qw(start stop restart reload status foreground show_warnings get_init_file) ) {
	subcommand $cmd => sub {
		$log->info( "Running $cmd on daemon" );
		$_[0]->_daemon->run_command($cmd)
	};
}

sub run {
	my ($self) = @_;
	$self->osprey_help(1);
}


1;

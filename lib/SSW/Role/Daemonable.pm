package SSW::Role::Daemonable;
# ABSTRACT: «TODO»

use Moo::Role;
use CLI::Osprey;

requires '_daemon';

for my $cmd ( qw(start stop restart reload status foreground show_warnings get_init_file) ) {
	subcommand $cmd => sub { $_[0]->_daemon->run_command($cmd) }
}

sub run {
	my ($self) = @_;
	$self->osprey_help(1);
}


1;

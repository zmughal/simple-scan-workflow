package SSW::Command;
# ABSTRACT: «TODO»

use Modern::Perl;
use Path::Tiny;
use File::Find::Rule;
use Mu;
use CLI::Osprey;

subcommand duckling => 'SSW::Daemon::Duckling';

subcommand watcher => 'SSW::Daemon::WatcherV1';

subcommand workflow => 'SSW::Workflow::V1';

subcommand ocr => 'SSW::Action::OCR';

sub run {
	my ($self) = @_;

	$self->osprey_help(1);
}

1;

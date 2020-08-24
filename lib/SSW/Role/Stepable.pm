package SSW::Role::Stepable;
# ABSTRACT: A role for a step

use Mu::Role;
use autodie qw(:all);

ro 'name';

ro 'bundle';

ro previous_step => (
	required => 0,
);

ro 'workflow';

rw 'output', required => 0;

lazy _directory_for_step => sub {
	my ($self) = @_;
	$self->workflow->_workflow_dir->child( $self->name );
};

sub run {
	...
}

sub mark_done {
	...
}

sub is_done {
	...
}

1;

package SSW::Role::Stepable::Doneable;
# ABSTRACT: A role to mark a step done

use Mu::Role;
use Try::Tiny;
use boolean;

requires 'read_meta';
requires 'write_meta';

around run => sub {
	my ($orig, $self, @args) = @_;

	if( $self->previous_step
		&& -f $self->meta_file
		&& -f $self->previous_step->meta_file
		&& $self->meta_file->stat->mtime < $self->previous_step->meta_file->stat->mtime
		) {

		$self->mark_undone;

	}

	if($self->is_done) {
		$self->output( $self->read_meta->{_step}{output} );
		return;
	}

	try {
		$self->$orig(@args)
	} catch {
		die $_;
	};

	my $data = $self->read_meta;
	$data->{_step}{output} = $self->output;
	$self->write_meta($data);
	$self->mark_done;
};

sub mark_done {
	my ($self) = @_;
	my $data = $self->read_meta;
	$data->{done} = true;
	$self->write_meta( $data );
}

sub mark_undone {
	my ($self) = @_;
	my $data = $self->read_meta;
	$data->{done} = false;
	$self->write_meta( $data );
}

sub is_done {
	my ($self) = @_;
	my $data = $self->read_meta;
	exists $data->{done} && $data->{done}
}

1;

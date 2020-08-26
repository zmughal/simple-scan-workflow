package SSW::Role::Stepable::Meta;
# ABSTRACT: A role for step metadata

use Mu::Role;

lazy meta_file => sub {
	my ($self) = @_;
	$self->_directory_for_step->child('.meta.json');
};

sub read_meta {
	my ($self) = @_;
	if( -f $self->meta_file ) {
		$self->_json->decode($self->meta_file->slurp_utf8);
	} else {
		return +{};
	}
}

sub write_meta {
	my ($self, $data) = @_;
	$self->meta_file->parent->mkpath;
	$self->meta_file->spew_utf8 (
		$self->_json->encode($data)
	);
}

with qw(SSW::Role::JSONSerializable);

1;

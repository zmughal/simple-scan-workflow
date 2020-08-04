package SSW::Data::Bundle;
# ABSTRACT: Bundle of data stored by SSW::Data::BundleRoot

use Moo;
use MooX::HandlesVia;
use MooX::ShortHas;

ro data => (
	handles_via => 'Hash',
	handles => +{
		( map { ( "data_$_" => [ qw(get), $_ ] ) }
			qw(path extension mtime sha256 bundle_name) )
	},
);

ro 'bundle_path';

lazy _bundle_archive => sub {
	my ($self) = @_;
	$self->bundle_path->child('.archive.zip');
};

lazy _bundle_meta => sub {
	my ($self) = @_;
	$self->bundle_path->child('.meta.json');
};

lazy bundle_name => sub {
	my ($self) = @_;
	$self->bundle_path->basename;
};

1;

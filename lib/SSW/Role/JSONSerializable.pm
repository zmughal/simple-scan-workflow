package SSW::Role::JSONSerializable;
# ABSTRACT: A role for JSON serialization

use Mu::Role;
use JSON::MaybeXS;

lazy _json => sub {
	my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
};

1;

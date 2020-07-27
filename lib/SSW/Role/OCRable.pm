package SSW::Role::OCRable;

use Moo::Role;
use CLI::Osprey;

option $_ => ( is => 'ro', format => 's', required => 1 ) for qw(input output);

1;

package SSW::Role::OCRable::Sidecar;
# ABSTRACT: Role for an OCR sidecar file

use Mu::Role;
use Path::Tiny;

requires 'output';

lazy sidecar_file => sub {
	my ($self) = @_;
	path($self->output . '.txt');
};

1;

package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

sub add_sources_genoverse {
  my $self = shift;
  $self->add_sources('genoverse', 'GENOVERSE_JS_NAME') if grep $_->[-1] eq 'genoverse', @{$self->hub->components};
}

1;

package EnsEMBL::Web::Document::Element::BodyJavascript;

use previous qw(init);

sub init {
  my $self = shift;
  
  $self->PREV::init;
  $self->add_sources('genoverse', 'GENOVERSE_JS_NAME') if grep $_->[-1] eq 'genoverse', @{$self->hub->components};
}

1;

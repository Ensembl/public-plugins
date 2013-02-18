package EnsEMBL::Admin::Command::Healthcheck::Annotation;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $reports = $object->rose_objects;
  my $anchor;

  for (@$reports) {

    my $annotation = $_->annotation || $_->annotation($object->rose_manager('Annotation')->create_empty_object);

    $annotation->comment($hub->param('comment'));
    $annotation->action($hub->param('action'));
    $annotation->session_id($_->last_session_id);
    $annotation->save('user' => $hub->user);
    
    $anchor ||= $_->database_name;
  }

  $self->ajax_redirect($hub->param('referrer') || $hub->url({'action' => 'Summary'}), {}, $anchor || '');
}

1;
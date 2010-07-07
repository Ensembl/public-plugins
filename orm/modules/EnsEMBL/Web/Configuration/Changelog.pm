package EnsEMBL::Web::Configuration::Changelog;

use strict;
use base qw( EnsEMBL::Web::Configuration );

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Summary';
}

sub short_caption {}
sub caption {}

sub global_context { return undef; }
sub ajax_content   { return undef; }
sub local_context  { return $_[0]->_local_context; }
sub local_tools    { return undef; }
sub context_panel  { return undef; }
sub content_panel  { return $_[0]->_content_panel;  }

sub populate_tree {
  my $self = shift;

  $self->create_node( 'Summary', 'Show all',
    [qw(summary EnsEMBL::ORM::Component::Changelog::Summary)], 
    { 'availability' => 1}
  );

}

1;

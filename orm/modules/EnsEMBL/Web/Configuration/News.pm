package EnsEMBL::Web::Configuration::News;

### NAME: EnsEMBL::Web::Configuration:News
### Default node and general settings for the News pages

### STATUS: Stable

### DESCRIPTION:
### A standard Configuration module. Note that by default, there are
### no CRUD nodes - these are added in the admin plugin, since most
### users won't need this functionality or wish it to be exposed on
### the web. There is however a custom display node so that non-admin
### users can view site news


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

  $self->create_node( 'Summary', "What's New in Ensembl",
    [qw(summary   EnsEMBL::ORM::Component::News::Summary)],
    {'availability' => 1},
  );

}

1;

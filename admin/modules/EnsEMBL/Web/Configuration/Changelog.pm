package EnsEMBL::Web::Configuration::Changelog;

### NAME: EnsEMBL::Web::Configuration::Changelog
### Default node and general settings for the Changelog pages

### STATUS: Stable

### DESCRIPTION:
### A standard Configuration module. Note that by default, there are
### no CRUD nodes - these are added in the admin plugin, since most
### users won't need this functionality or wish it to be exposed on
### the web. There is however a custom display node so that non-admin
### users can view relevant entries from the changelog

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Summary';
}

sub short_caption {}
sub caption {}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('global_context');
  $page->remove_body_element('local_tools');
  $page->remove_body_element('context_panel');
}

sub populate_tree {
  my $self = shift;

  $self->create_node( 'Summary', 'View all',
    [qw(summary EnsEMBL::Admin::Component::Changelog::Summary)], 
    { 'availability' => 1 }
  );
}

sub modify_tree {
  my $self = shift;
  $self->add_dbfrontend_to_tree([ 'WebAdmin' ]); ## Add defaults
}

1;

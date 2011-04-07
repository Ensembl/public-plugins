package EnsEMBL::Web::Configuration::Webdata;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

sub short_caption { 'Webdata'; }
sub caption       { 'Webdata'; }

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('tabs');
  $page->remove_body_element('tool_buttons');
  $page->remove_body_element('summary');
}

sub populate_tree {
  my $self = shift;

  $self->create_all_dbfrontend_nodes(['WebAdmin']);
}

1;
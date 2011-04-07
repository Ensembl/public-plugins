package EnsEMBL::Web::Configuration::AnalysisWebdata;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Display';
}

sub short_caption { 'Analysis Webdata'; }
sub caption       { 'Analysis Webdata'; }

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('tabs');
  $page->remove_body_element('tool_buttons');
  $page->remove_body_element('summary');
}

sub populate_tree {
  my $self = shift;

  $self->create_dbfrontend_node({'Display' => {'filters' => ['WebAdmin']}});
  $self->create_dbfrontend_node({'Add'     => {'filters' => ['WebAdmin'], 'no_menu_entry' => 1}});
  $self->create_dbfrontend_node({$_        => {'filters' => ['WebAdmin']}}) for qw(Edit Preview Problem Confirm Save Delete);
}

1;
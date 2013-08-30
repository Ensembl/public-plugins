package EnsEMBL::Web::Configuration::Search;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub modify_tree {
  my $self   = shift;

  ## Replace results component with one from SOLR namespace
  my $node = $self->get_node('Results');
  $node->data->{'components'} = [qw(results   EnsEMBL::Solr::Component::Search::Results)];
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
#  $page->remove_body_element('tabs');
#  $page->remove_body_element('tool_buttons');
#  $page->remove_body_element('summary');
}
1;

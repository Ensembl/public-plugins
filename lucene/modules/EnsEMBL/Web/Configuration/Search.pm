package EnsEMBL::Web::Configuration::Search;

use strict;

sub modify_tree {
  my $self   = shift;

  ## Replace results component with one from Lucene namespace
  my $node = $self->get_node('Results');
  $node->data->{'components'} = [qw(results   EnsEMBL::Lucene::Component::Search::Results)];

  ## Extra step - Results is now a summary
  $self->create_node('Details', 'Result in Detail',
    [qw(details   EnsEMBL::Lucene::Component::Search::Details)],
    { 'no_menu_entry' => 1 }
  );
}

1;

package EnsEMBL::Web::Configuration::Search;

use strict;

sub modify_tree {
  my $self   = shift;

  ## Replace results node with one from Lucene namespace
  $self->delete_node('Results');
  $self->create_node('Results', 'Results Summary',
    [qw(results   EnsEMBL::Lucene::Component::Search::Results)],
    { no_menu_entry => 1 }
  );

  $self->create_node('Details', 'Result in Detail',
    [qw(details   EnsEMBL::Lucene::Component::Search::Details)],
    { 'no_menu_entry' => 1 }
  );
}

1;

package EnsEMBL::Admin::Component::HelpRecord::Display;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub record_tree {
  ## @overrides
  ## Overrides the default one to print corresponding youtube video link for youtube_id field
  my $record_div  = shift->SUPER::record_tree(@_);
  my $youtube_div = $record_div->get_nodes_by_flag('data.youtube_id');
  if (@$youtube_div) {
    $youtube_div = $youtube_div->[0]->last_child;
    if (my $youtube_id = $youtube_div->inner_HTML) {
      $youtube_div->inner_HTML(sprintf '<a href="http://www.youtube.com/watch?v=%s">%1$s</a>', $youtube_id);
    }
  }
  return $record_div;
}

1;
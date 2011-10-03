package EnsEMBL::Admin::Component::HelpRecord::Display;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub record_tree {
  my $record_div  = shift->SUPER::record_tree(@_);
  my $youtube_div = $record_div->get_nodes_by_flag('data.youtube_id');
  if (@$youtube_div) {
    $youtube_div = $youtube_div->[0]->last_child;
    $youtube_div->inner_HTML(sprintf '<a href="http://www.youtube.com/watch?v=%s">%1$s</a>', $youtube_div->inner_HTML) if $youtube_div->inner_HTML;
  }
  return $record_div;
}

1;
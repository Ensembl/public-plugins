package EnsEMBL::Admin::Component::HelpRecord::List;

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::List);

sub record_tree {
  ## @overrides
  ## Overrides the default one to print corresponding youtube video link for youtube_id field
  my $record_div  = shift->SUPER::record_tree(@_);
  my $youtube_div = $record_div->get_nodes_by_flag('data.youtube_id');
  my $youku_div   = $record_div->get_nodes_by_flag('data.youku_id');

  if (@$youtube_div) {
    $youtube_div = $youtube_div->[0];
    if (my $youtube_id = $youtube_div->inner_HTML) {
      $youtube_div->inner_HTML(sprintf '%s (<a href="http://www.youtube.com/watch?v=%1$s" target="_blank">View on YouTube</a>)', $youtube_id);
    }
  }

  if (@$youku_div) {
    $youku_div = $youku_div->[0];
    if (my $youku_id = $youku_div->inner_HTML) {
      $youku_div->inner_HTML(sprintf '%s (<a href="http://v.youku.com/v_show/id_%1$s.html" target="_blank">View on YouKu</a>)', $youku_id);
    }
  }

  return $record_div;
}

1;
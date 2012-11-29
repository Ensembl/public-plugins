package EnsEMBL::Admin::Component::HelpRecord::Display;

use strict;
use warnings;

use base qw(
  EnsEMBL::ORM::Component::DbFrontend::Display
  EnsEMBL::Web::Component::Help
);

sub record_tree {
  ## @overrides
  ## Overrides the default one to print corresponding youtube video link for youtube_id field
  my $self        = shift;
  my $record_div  = $self->SUPER::record_tree(@_);
  my $code_div    = $record_div->get_nodes_by_flag('help_record_id');
  my $youtube_div = $record_div->get_nodes_by_flag('data.youtube_id');
  my $youku_div   = $record_div->get_nodes_by_flag('data.youku_id');
  my $html_div    = $record_div->get_nodes_by_flag(['data.answer', 'data.content']);

  if (@$code_div && $code_div->[0]->first_child->inner_HTML =~ /movie/i) {
    $code_div = $code_div->[0]->last_child;
    $code_div->inner_HTML(sprintf '%s (embed code: <span class="code">[[movie=%1$s]]</span>)', $code_div->inner_HTML);
  }

  if (@$youtube_div) {
    $youtube_div = $youtube_div->[0]->last_child;
    if (my $youtube_id = $youtube_div->inner_HTML) {
      $youtube_div->inner_HTML(sprintf '%s (<a href="http://www.youtube.com/watch?v=%1$s" target="_blank">View on YouTube</a>)', $youtube_id);
    }
  }

  if (@$youku_div) {
    $youku_div = $youku_div->[0]->last_child;
    if (my $youku_id = $youku_div->inner_HTML) {
      $youku_div->inner_HTML(sprintf '%s (<a href="http://v.youku.com/v_show/id_%1$s.html" target="_blank">View on YouKu</a>)', $youku_id);
    }
  }

  if (@$html_div) {
    $html_div = $html_div->[0]->last_child;
    $html_div->inner_HTML($self->parse_help_html($html_div->inner_HTML, $self->object));
  }

  return $record_div;
}

1;
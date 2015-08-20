=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Admin::Component::HelpRecord::List;

use strict;
use warnings;

use parent qw(EnsEMBL::ORM::Component::DbFrontend::List);

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
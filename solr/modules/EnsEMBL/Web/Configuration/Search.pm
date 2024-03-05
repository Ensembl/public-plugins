=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Search;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub default_template { 'Legacy::AltNav' }

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

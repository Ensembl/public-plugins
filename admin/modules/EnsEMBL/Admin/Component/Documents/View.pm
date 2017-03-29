=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Documents::View;

use strict;

use parent qw(EnsEMBL::Admin::Component::Documents);

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;

  return $self->get_display_html if $hub->function;

  my $docs    = $object->available_documents;
  my $list    = '';
  while (my ($function, $doc) = splice @$docs, 0, 2) {
    $list .= sprintf('<li><a href="%s">%s</a></li>', $hub->url({'action' => 'View', 'function' => $function}), $doc->{'title'});
  }
  return $list ? "<h2>Document list</h2><p>Please select a document below to view:<ul>$list</ul></p>" : '<h2>No document found</h2><p>There is no document to display</p>';
}

1;
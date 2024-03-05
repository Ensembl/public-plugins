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

package EnsEMBL::Web::Component::Tools::Icons;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable(0);
}

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my @tool_types  = $hub->species_defs->tools_list;
  my $html        = '';

  for (@tool_types) {
    while (my ($key, $caption) = splice @tool_types, 0, 2) {
      $html .= sprintf '<p><a href="%s">%s</a>', $hub->url({'action' => $key}), $caption;
    }
  }

  return $html;
}

1;

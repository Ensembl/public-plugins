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

package EnsEMBL::Web::Document::Element::ToolLinks;

use strict;
use warnings;

use previous qw(links);

sub links {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $hub->species_defs;
  my $links = $self->PREV::links(@_);

  my %tools = @{$hub->species_defs->ENSEMBL_TOOLS_LIST};

  unshift @$links, 'tools',         '<a class="constant" href="/info/docs/tools/index.html">Tools</a>';

  unshift @$links, 'vep', '<a class="constant" href="/info/docs/tools/vep/">VEP</a>' if $sd->ENSEMBL_VEP_ENABLED;

  if ($sd->ENSEMBL_BLAST_ENABLED) {
    unshift @$links, 'blast', sprintf '<a class="constant" href="%s">%s</a>', $hub->url({'species' => $hub->species || 'Multi', 'type' => 'Tools', 'action' => 'Blast', 'function' => ''}), $tools{'Blast'};
  }

  return $links;
}

1;

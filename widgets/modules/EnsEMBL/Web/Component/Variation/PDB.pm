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

package EnsEMBL::Web::Component::Variation::PDB;

use strict;

use HTML::Entities qw(encode_entities);
use URI::Escape;
#use EnsEMBL::Web::Component::PDB qw(get_rest_urls);

use base qw(EnsEMBL::Web::Component::Variation EnsEMBL::Web::Component::PDB);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self      = shift;

  my $hub       = $self->hub;
  my $object    = $self->object;
  my $variation = $object->Obj;
  my $species   = $hub->species;
  
  my $var_id    = $hub->param('v');
  my $var_label = $var_id."_cb";
  my $vf        = $hub->param('vf');

  my $variation_features = $variation->get_all_VariationFeatures;
  my $msc;

  foreach my $vf_object (@$variation_features) {
    if ($vf_object->dbID == $vf) {
      my $overlap_consequences = [$vf_object->most_severe_OverlapConsequence] || [];
      # Sort by rank, with only one copy per consequence type
      my @consequences = sort {$a->rank <=> $b->rank} (values %{{map {$_->label => $_} @{$overlap_consequences}}});
      $msc = $consequences[0];
      last;
    }
  }

  return "No overlapping protein" unless ($msc && $msc->rank < 17);

  # Add REST API URLs as hidden param
  my $html = $self->get_rest_urls();
  
  # Add IDs header
  $html .= $self->get_ids_header($var_id);

  # Add selection dropdowns
  $html .= $self->get_ensp_pdb_dropdowns(1);

  # Litmol viewer + right hand side menu
  $html .= $self->get_main_content($var_id);

  return $html;
}

1;

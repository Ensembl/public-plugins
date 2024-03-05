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

package EnsEMBL::Web::Component::VEP::AFDB;

use strict;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);  
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $species     = $hub->species;
  my $ensembl_rest_url = $hub->species_defs->ENSEMBL_REST_URL;

  my $transcript_adaptor = $hub->get_adaptor('get_TranscriptAdaptor');

  my $transcript_id = $hub->param('t');
  my $variant_label = $hub->param('var');
  my $variant_position = $hub->param('pos');
  my $variant_consequence = $hub->param('cons');

  my $transcript  = $transcript_adaptor->fetch_by_stable_id($transcript_id);
  my $translation = $transcript->translation();
  my $translation_id = $translation->stable_id;

  my $data_attributes = '';
  $data_attributes .= qq{data-species="$species" }; # FIXME: won't be needed if not showing all variants
  $data_attributes .= qq{data-ensp-id="$translation_id" };
  $data_attributes .= qq{data-rest-url-root="$ensembl_rest_url" };
  $data_attributes .= qq{data-variant-label="$variant_label" };
  $data_attributes .= qq{data-variant-position="$variant_position" };
  $data_attributes .= qq{data-variant-consequence="$variant_consequence" };

  
  return qq{
    <input class="panel_type" value="AFDB" type="hidden" />
    <h2 id="mappings_top">
      Ensembl protein: $translation_id
    </h2>
    <div id="afdb_msg"></div>
    <div>
      <div>
        <div class="view_spinner" style="display:none"></div>
        <div id="alphafold_container">
          <ensembl-alphafold-vep $data_attributes style="visibility: hidden">
          </ensembl-alphafold-vep>
        </div>
      </div>
      <div style="clear:both"></div>
    </div>
  };
}

1;

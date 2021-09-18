=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2019] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::AFDB;

use strict;

use base qw(EnsEMBL::Web::Component::Shared);


sub get_rest_urls {
  my $self = shift;
  my $hub  = $self->hub;

  my $ensembl_rest_url = $hub->species_defs->ENSEMBL_REST_URL;
  my $afdb_url         = $hub->species_defs->AFDB_URL;

  return qq{
    <input class="panel_type" value="AFDB" type="hidden" />
    <input type="hidden" name="ensembl_rest_url" class="js_param" value="$ensembl_rest_url">
    <input type="hidden" name="afdb_url" class="js_param" value="$afdb_url">
  };
}

sub get_ids_header {
  my $self   = shift;
  my $ensp_id = shift;

  return qq{
  <h2 id="mappings_top">
    Ensembl protein: $ensp_id
  </h2>

  <div id="afdb_msg"></div>
  };
}


sub get_main_content {
  my $self = shift;
  my $viewer_container = $self->get_viewer_container();

  return qq{
  <div>
    $viewer_container
    <div style="clear:both"></div>
  </div>
  }
}

sub get_viewer_container {
  my $self = shift;

  return qq{
    <div>
      <div class="view_spinner" style="display:none"></div>
      <div id="alphafold_container">
        <!-- Alphafold element -->
      </div>
    </div>
  }
}

1;

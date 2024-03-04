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

package EnsEMBL::Solr::Component::Search::Results;

use strict;

use base qw(EnsEMBL::Web::Component::Search);

use JSON;
use HTML::Entities;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub escape {
  local $_ = shift;
  s/&/&amp;/g;
  s/</&lt;/g;
  s/>/&gt;/g;
  return $_;
}

sub common {
  my ($self,$scientific) = @_;

  return $self->hub->species_defs->get_config($scientific,'SPECIES_COMMON_NAME');
}

sub content {
  my $self = shift;
  my $hub = $self->hub;

  # Species
  my $species = $self->common($hub->species);

  # Columns
  # Encode

  # Misc further config
  my $base = $hub->species_defs->ENSEMBL_BASE_URL;
  $base = encode_json({ url => $base});
  
  # Emit them
  return qq(
    <div>
      <div id='solr_context'>
        <span id='facet_species'>$species</span>
      </div>
      <div id='solr_config'>
        <span class='base'>$base</span>
      </div>
      <div id='solr_templates'>
        <div id='table_main'>
          <table style="width: 100%" class="table_body">
          </table>
        </div>
      </div>
      <div id='solr_content'></div>
    </div>
);

  return "<div id='solr_content'></div>";
}

1;

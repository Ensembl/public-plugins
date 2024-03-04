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

package EnsEMBL::Web::Component::Info;

use strict;

use EnsEMBL::Web::Controller::SSI;


sub ftp_url {
  my $self = shift;
  return $self->hub->species_defs->ENSEMBL_FTP_URL;
}


sub include_more_annotations {
  my $self              = shift;
  my $hub               = $self->hub;
  my $species           = $hub->species;

  my $html = '';

  $html .= qq(<h2 id="variation">Variation annotation</h2>
<p>We have imported variation data from a variety of sources including ENA, EVA, NextStrain and COG UK. See the main <a href="/$species/Info/Variation">SARS-CoV-2 variation page</a> for information on how data from each source is selected and displayed.</p>
  );

  $html .= '<h2 id="compara">Comparative annotation</h2>';
  $html .= EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, "/ssi/species/${species}_compara.html");

  $html .= '<h2 id="references">References</h2>';
  $html .= EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, "/ssi/species/${species}_references.html");

  return $html;
}

1;

=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;

use previous qw(init);

sub init {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  my $type         = $self->hub->type;
  
  $self->PREV::init(@_);
  $self->add_sheet('all', sprintf '/%s/%s.css', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->SOLR_CSS_NAME) if $type and $type eq 'Search'; 
}

1;


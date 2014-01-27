=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

use previous qw(init);

use EnsEMBL::Web::Tools::JavascriptOrder;

sub init {
  my $self = shift;
  
  $self->PREV::init;
  
  return unless grep $_->[-1] eq 'genoverse', @{$self->hub->components};
  
  my $species_defs = $self->species_defs;
  
  if ($self->debug) {
    $self->add_source($_) for EnsEMBL::Web::Tools::JavascriptOrder->new({ species_defs => $species_defs })->order;
  } else {
    $self->add_source(sprintf '/%s/%s.js', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->GENOVERSE_JS_NAME);
  }
}

1;

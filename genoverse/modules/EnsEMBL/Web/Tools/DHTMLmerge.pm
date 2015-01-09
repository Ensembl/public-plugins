=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

###############################################################################
#   
#   Name:        EnsEMBL::Web::Tools::DHTMLmerge
#    
#   Description: Populates templates for static content.
#                Run at server startup
#
###############################################################################

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use previous qw(merge_all);

use EnsEMBL::Web::Tools::JavascriptOrder;

sub merge_all {
  my $species_defs = $_[0];
  my $contents;
  
  {
    local $/ = undef;
  
    foreach (EnsEMBL::Web::Tools::JavascriptOrder->new({ species_defs => $species_defs, absolute_path => 1 })->order) {
      open I, $_;
      $contents .= <I>;
      close I;
    }
  }
  
  $species_defs->{'_storage'}{'GENOVERSE_JS_NAME'} = compress($species_defs, 'js', $contents);
  
  PREV::merge_all(@_);
}

1;

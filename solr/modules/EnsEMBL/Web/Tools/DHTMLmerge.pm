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

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;

use previous qw(merge_all);

sub merge_all {
  my $species_defs = $_[0];
  my $dir          = [split 'modules', __FILE__]->[0] . 'htdocs';
  
  $species_defs->{'_storage'}{'SOLR_JS_NAME'}  = merge($species_defs, 'js',  $dir, 'solr');
  $species_defs->{'_storage'}{'SOLR_CSS_NAME'} = merge($species_defs, 'css', $dir, 'solr');

  PREV::merge_all(@_);
}

1;

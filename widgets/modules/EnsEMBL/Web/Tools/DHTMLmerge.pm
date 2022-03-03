=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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
use warnings;

use previous qw(get_filegroups);

sub get_filegroups {
  ## @override
  my ($species_defs, $type) = @_;

  return PREV::get_filegroups($species_defs, $type), $type eq 'js' ? {
    'group_name'  => 'widgets',
    'files'       => get_files_from_dir($species_defs, $type, 'widgets'),
    'condition'   => sub { $_[0]->apache_handle->unparsed_uri =~ /speciestree\.html/ || ($_[0]->action || '') =~ /SpeciesTree|ExpressionAtlas|Pathway/; },
    'ordered'     => 0
  } : ();
}

1;

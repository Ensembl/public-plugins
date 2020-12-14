=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;

sub _get_NCBIBLAST_source_file {
  ## @private
  my ($self, $species, $source_type) = @_;

  my $assembly  = $self->get_config($species, 'ASSEMBLY_ACCESSION');
  my $type      = lc($source_type =~ s/_/\./r);
  my $sp_name   = ucfirst($self->get_config($species, 'STRAIN_GROUP')
                        || $self->get_config($species, 'SPECIES_DB_NAME')
                        || $self->get_config($species, 'SPECIES_PRODUCTION_NAME'));

  return sprintf '%s-%s-%s.fa', $sp_name, $assembly, $type unless $type =~ /latestgp/;

  if ($type =~ /soft/) {
    $type = 'softmasked';
  }
  elsif ($type =~ /mask/) {
    $type = 'hardmasked';
  }
  else {
   $type = 'unmasked'; 
  }

  return sprintf '%s-%s-%s.fa', $sp_name, $assembly, $type;
}

1;

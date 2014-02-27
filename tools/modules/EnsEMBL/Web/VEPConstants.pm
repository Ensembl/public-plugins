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

package EnsEMBL::Web::VEPConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(INPUT_FORMATS CONFIG_SECTIONS);

sub INPUT_FORMATS {
  return [
    { 'value' => 'ensembl', 'caption' => 'Ensembl default',     'example' => qq(1  909238  909238  G/C  +\n3  361464  361464  A/-  +\n5  121187650  121188519  DUP) },
    { 'value' => 'vcf',     'caption' => 'VCF',                 'example' => qq(1  909238  var1  G  C  .  .  .\n3  361463  var2  GA  G  .  .  .\n5  121187650 sv1   .  &lt;DUP&gt;  .  .  SVTYPE=DUP;END=121188519  .) },
    { 'value' => 'pileup',  'caption' => 'Pileup',              'example' => qq(chr5  881906  T  C) },
    { 'value' => 'id',      'caption' => 'Variant identifiers', 'example' => qq(rs699\nrs144678492\nCOSM354157) },
    { 'value' => 'hgvs',    'caption' => 'HGVS notations',      'example' => qq(ENST00000207771.3:c.344+626A>T\nENST00000471631.1:c.28_33delTCGCGG) }
  ];
}

sub CONFIG_SECTIONS {

}

1;

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

package EnsEMBL::Web::VEPConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(INPUT_FORMATS CONFIG_SECTIONS REST_DISPATCHER_FILESIZE_LIMIT REST_DISPATCHER_SERVER_ENDPOINT);

sub INPUT_FORMATS {
  return [
    { 'value' => 'ensembl', 'caption' => 'Ensembl default',     'example' => qq(1  909238  909238  G/C  +\n3  361464  361464  A/-  +\n5  121187650  121188519  DUP) },
    { 'value' => 'vcf',     'caption' => 'VCF',                 'example' => qq(1  909238  var1  G  C  .  .  .\n3  361463  var2  GA  G  .  .  .\n5  121187650 sv1   .  &lt;DUP&gt;  .  .  SVTYPE=DUP;END=121188519  .) },
    { 'value' => 'id',      'caption' => 'Variant identifiers', 'example' => qq(rs699\nrs144678492\nRCV000004642) },
    { 'value' => 'hgvs',    'caption' => 'HGVS notations',      'example' => qq(ENST00000207771.3:c.344+626A>T\nENST00000471631.1:c.28_33delTCGCGG) },
    { 'value' => 'spdi',    'caption' => 'SPDI',                'example' => qq(1:230710044:A:G) },
  ];
}

sub CONFIG_SECTIONS {
  return [{
    'id'            => 'identifiers',
    'title'         => 'Identifiers',
    'caption'       => 'Additional identifiers for genes, transcripts and variants'
  }, {
    'id'            => 'variants_frequency_data',
    'title'         => 'Variants and frequency data',
    'caption'       => 'Co-located variants and frequency data',
    'check_has_var' => 1
  }, {
    'id'            => 'additional_annotations',
    'title'         => 'Additional annotations',
    'caption'       => 'Addtional transcript, protein and regulatory annotations'
  }, {
    'id'            => 'predictions',
    'title'         => 'Predictions',
    'caption'       => 'Variant predictions, e.g. SIFT, PolyPhen'
  }, {
    'id'            => 'filters',
    'title'         => 'Filtering options',
    'caption'       => 'Pre-filter results by frequency or consequence type'
  }, {
    'id'            => 'advanced',
    'title'         => 'Advanced options',
    'caption'       => 'Settings to optimise VEP'
  # }, {
  #  'id'        => 'plugins',
  #  'title'     => 'Plugins',
  #  'caption'   => 'Extra functionality from VEP plugins'
  }];
}

sub REST_DISPATCHER_SERVER_ENDPOINT {
  return 'http://rest.ensembl.org/vep/:species/region/';
}

sub REST_DISPATCHER_FILESIZE_LIMIT {
  ## Size of the input file in bytes below which job should be processed by using the REST server
  return 0; # disabled
}

1;

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

package EnsEMBL::Web::VRConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(INPUT_FORMATS REST_DISPATCHER_FILESIZE_LIMIT REST_DISPATCHER_SERVER_ENDPOINT);

sub INPUT_FORMATS {
  return [
    { 'value' => 'id',        'caption' => 'Variant ID',      'example' => qq(rs699\nrs144678492\nRCV000004642) },
    { 'value' => 'hgvsg',     'caption' => 'HGVS genomic',    'example' => qq(NC_000009.12:g.133256042C>T\nNC_000001.11:g.230710048A>G) },
    { 'value' => 'hgvsc',     'caption' => 'HGVS transcript', 'example' => qq(ENST00000207771.3:c.344+626A>T\nENST00000471631.1:c.28_33delTCGCGG) },
    { 'value' => 'hgvsp',     'caption' => 'HGVS protein',    'example' => qq(ENSP00000355627.4:p.Met259Thr\nENSP00000483018.1:p.Gly229Asp) },
    { 'value' => 'spdi',      'caption' => 'SPDI',            'example' => qq(1:230710044:A:G\n9:133256041:C:T) },
  ];
}

sub REST_DISPATCHER_SERVER_ENDPOINT {
  return 'http://rest.ensembl.org/variant_recoder/:species/';
}

sub REST_DISPATCHER_FILESIZE_LIMIT {
  ## Size of the input file in bytes below which job should be processed by using the REST server
  return 0; # disabled
}

1;

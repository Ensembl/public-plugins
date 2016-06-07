=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::FileChameleonConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(INPUT_FORMATS STYLE_FORMATS CONVERSION_FORMATS);

sub INPUT_FORMATS {
  return [
    { 'value' => 'null',  'caption' => 'choose file format',  'example' => qq() },
    { 'value' => 'GFF3',  'caption' => 'GFF3',  'example' => qq() },
    { 'value' => 'GTF',   'caption' => 'GTF',  'example' => qq() },
  ];
}

sub CONVERSION_FORMATS {
  return [
    { 'value' => 'bowtie',  'caption' => 'BOWTIE',  'example' => qq() },
    { 'value' => 'bwa',   'caption' => 'BWA',  'example' => qq() },
    { 'value' => 'bbmap',   'caption' => 'BBMap',  'example' => qq() },
    { 'value' => 'bwa',   'caption' => 'BWA',  'example' => qq() },
    { 'value' => 'start',   'caption' => 'STAR',  'example' => qq() },
    { 'value' => 'custom',   'caption' => 'Customise options',  'example' => qq() },
  ];
}

sub STYLE_FORMATS {
  return [
    { 'value' => 'null',   'caption' => '',  'example' => qq() },
    { 'value' => 'ensembl_to_ucsc',   'caption' => 'Ensembl to UCSC',  'example' => qq() },
    { 'value' => 'ucsc_to_ensembl',   'caption' => 'UCSC to Ensembl',  'example' => qq() },
    { 'value' => 'ensembl_to_insdc',  'caption' => 'Ensembl to INSDC', 'example' => qq() },
    { 'value' => 'insdc_to_ensembl',  'caption' => 'INSDC to Ensembl', 'example' => qq() },
  ];
}

1;

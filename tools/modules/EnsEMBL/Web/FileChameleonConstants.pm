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

package EnsEMBL::Web::FileChameleonConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(INPUT_FORMATS STYLE_FORMATS CONVERSION_FORMATS);

sub INPUT_FORMATS {
  return [
    { 'value' => 'gff3',  'caption' => 'GFF3', 'example' => qq(), 'checked' => "checked" },
    { 'value' => 'gtf',   'caption' => 'GTF',  'example' => qq() },
    { 'value' => 'fasta', 'caption' => 'FASTA','example' => qq() },
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
    { 'value' => 'ucsc_to_ensembl',   'caption' => 'Ensembl style',  'example' => qq(), 'selected' => 'selected' },
    { 'value' => 'ensembl_to_ucsc',   'caption' => 'UCSC style',  'example' => qq() },
  ];
}

1;

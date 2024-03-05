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

package EnsEMBL::Web::Job::AssemblyConverter;

### plugin to add extra parameters to AssemblyConverter job before submitting it to Hive dispatcher

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileSystem qw(create_path);
use EnsEMBL::Web::Exceptions qw(WebError);

use previous qw(prepare_to_dispatch);

sub prepare_to_dispatch {
  ## @plugin
  my $self    = shift;
  my $data    = $self->PREV::prepare_to_dispatch(@_) or return;
  my $sd      = $self->hub->species_defs;
  my $format  = $data->{'config'}{'format'};

  $data->{'AC_bin_path'}  = $sd->ASSEMBLY_CONVERTER_BIN_PATH;
  $data->{'data_dir'}     = $sd->ENSEMBL_CHAIN_FILE_DIR;

  # for wig, we need to provide wigToBigWig and bigWigToWig
  if ($format eq 'wig') {

    my ($extra_path) = @{create_path("$data->{'work_dir'}/bin")};

    # symlink these to a local bin directory for the RunnableDB to add them to $PATH while executing
    symlink($sd->WIGTOBIGWIG_BIN_PATH, "$extra_path/wigToBigWig") or throw WebError('Error linking wigToBigWig');
    symlink($sd->BIGWIGTOWIG_BIN_PATH, "$extra_path/bigWigToWig") or throw WebError('Error linking bigWigToWig');

    $data->{'extra_PATH'} = $extra_path;
  }

  return $data;
}

1;

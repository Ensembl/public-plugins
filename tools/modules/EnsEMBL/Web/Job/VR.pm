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

package EnsEMBL::Web::Job::VR;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Job);

sub prepare_to_dispatch {
  ## @override
  my $self        = shift;
  my $rose_object = $self->rose_object;
  my $job_data    = $rose_object->job_data;
  my $species     = $job_data->{'species'};
  my $sd          = $self->hub->species_defs;
  my $vr_configs = {};

  $vr_configs->{'species'} = lc $species;

  # i/o files
  $vr_configs->{'input_file'}  = $job_data->{'input_file'};

  $vr_configs->{'result_headers'}  = $job_data->{'result_headers'};

  # extra and identifiers
  $job_data->{$_} and $vr_configs->{$_} = $job_data->{$_} for qw(id spdi hgvsc hgvsg hgvsp vcf_string var_synonyms mane_select);

  return {
    'species' => $vr_configs->{'species'},
    'work_dir' => $rose_object->job_dir,
    'config' => $vr_configs
  };
}

1;

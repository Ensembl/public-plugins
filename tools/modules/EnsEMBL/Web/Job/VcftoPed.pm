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

package EnsEMBL::Web::Job::VcftoPed;

use strict;
use warnings;

use JSON qw(to_json);

use EnsEMBL::Web::Utils::FileHandler qw(file_put_contents);
use EnsEMBL::Web::File::Utils::URL;

use parent qw(EnsEMBL::Web::Job);

sub prepare_to_dispatch {
  ## @override
  my $self        = shift;
  
  my $rose_object = $self->rose_object;
  my $job_data    = $rose_object->job_data;
  my $region      = $job_data->{'region'};
  my $bgzip       = $self->hub->species_defs->BGZIP;
  (my $output_ped  = $region) =~ s/:/_/;
  (my $output_info = $region) =~ s/:/_/;
  
  
  return {
    'work_dir'      => $rose_object->job_dir,
    'tools_dir'     => $self->hub->species_defs->SHARED_SOFTWARE_PATH,
    'bgzip'         => $bgzip,
    'input_file'    => $job_data->{'file_url'},
    'region'        => $job_data->{'region'},
    'base'          => $job_data->{'base'},
    'biallelic'     => $job_data->{'biallelic'} ? 1 : 0,
    'population'    => $job_data->{'population'},   
    'sample_panel'  => $job_data->{'sample_panel'},
    'output_ped'    => $output_ped.".ped",
    'output_info'   => $output_info.".info",
    'proxy'         => $self->hub->web_proxy,
    'code_root'     => $self->hub->species_defs->ENSEMBL_HIVE_HOSTS_CODE_LOCATION
  };
}

1;

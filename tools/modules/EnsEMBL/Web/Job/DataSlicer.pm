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

package EnsEMBL::Web::Job::DataSlicer;

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
  my $job_dir     = $rose_object->job_dir;
  my $script_dir  = $self->hub->species_defs->THOUSANDG_TOOLS_DIR;
  my $tabix       = $self->hub->species_defs->TABIX;
  my $bgzip       = $self->hub->species_defs->BGZIP; 
  my $samtools    = $self->hub->species_defs->SAMTOOLS;   
  my @path        = split('/', $job_data->{'file_url'});
  
  my ($dispatcher_hash, $output_file);
  
  if($job_data->{'file_format'} eq 'vcf') {
    $dispatcher_hash->{'population_value'}  = $job_data->{'population_value'};
    $dispatcher_hash->{'individuals'}       = $job_data->{'individuals_box'} ? $job_data->{'individuals_box'} : $job_data->{'individuals_text'};
    $dispatcher_hash->{'upload_type'}       = $job_data->{'upload_type'};
    $dispatcher_hash->{'vcf_filters'}       = $job_data->{'vcf_filters'};
    
    ($output_file = $job_data->{'region'} . '.' . $path[-1]) =~ s/\:/\./g;
    #$output_file = 'filtered_'.$output_file if($job_data->{'vcf_filters'} ne 'null'); #if filter is either individuals or populations, output name is different
    
  } else {
    #BAM format
    $dispatcher_hash->{'bai_file'} = $job_data->{'bai_file'};    
    ($output_file = $job_data->{'region'} . '.' . $path[-1]) =~ s/\:/\./g;
  }
  
  return {
    'work_dir'      => $job_dir,
    'script_dir'    => $script_dir,
    'tabix'         => $tabix,
    'bgzip'         => $bgzip,
    'samtools'      => $samtools,    
    'output_file'   => $output_file,
    'input_file'    => $job_data->{'file_url'},
    'file_format'   => $job_data->{'file_format'},
    'region'        => $job_data->{'region'},    
    'code_root'     => $self->hub->species_defs->ENSEMBL_HIVE_HOSTS_CODE_LOCATION,
    %$dispatcher_hash,
  };
}

1;

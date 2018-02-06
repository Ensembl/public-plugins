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

package EnsEMBL::Web::Job::AlleleFrequency;

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
  my $region      = $job_data->{'region'};
  my $population  = $job_data->{'population'};
  my $file_url    = $job_data->{'file_url'};
  my $proxy       = $self->hub->web_proxy;
  my $tabix       = $self->hub->species_defs->TABIX;
  my $bgzip       = $self->hub->species_defs->BGZIP;
  my $tools_dir   = $self->hub->species_defs->SHARED_SOFTWARE_PATH;
  
  # output file name, storing it in db for checking content
  my $output_file = "afc.".($region =~ s/:/./r).".proc$$.tsv";
    
  # download sample file  to work dir
  my $args        = {'no_exception' => 1 };
  $args->{proxy}  = $proxy ? $proxy : "";  
  $args->{nice}   = 1;  
  $args->{destination_path} = "$job_dir/";
  
  my $sample_file = EnsEMBL::Web::File::Utils::URL::fetch_file($job_data->{'sample_panel'}, $args);

  if(ref($sample_file) eq 'HASH' && $sample_file->{error}) {
    throw exception('HiveException', "Job failed, Sample panel file cannot be found: ".$sample_file->{error});
  }

  return {
    'work_dir'      => $job_dir,
    'output_file'   => $output_file,
    'input_file'    => $file_url,
    'tools_dir'     => $tools_dir,    
    'tabix'         => $tabix,
    'bgzip'         => $bgzip,
    'region'        => $job_data->{'region'},
    'population'    => $job_data->{'population'},
    'sample_panel'  => $sample_file,
    'proxy'         => $proxy,
    'code_root'     => $self->hub->species_defs->ENSEMBL_HIVE_HOSTS_CODE_LOCATION
  };
}

1;

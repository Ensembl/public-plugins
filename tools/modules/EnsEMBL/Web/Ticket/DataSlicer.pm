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

package EnsEMBL::Web::Ticket::DataSlicer;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::DataSlicer;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self    = shift;
  my $hub     = $self->hub;
  my $species = $hub->param('species');
  my $format  = $hub->param('file_format');
  my $region  = uc($hub->param('region') // '') =~ s/[^A-Z0-9_\:\-]//gr; # remove unwanted chars (eg. spaces and commas)
 
  my ($fix_sample_url, $population, $job_desc, $job_hash);
  
  throw exception('InputError', 'No input data is present') unless $hub->param('bam_file_url') || $hub->param('custom_file_url') || $hub->param('generated_file_url');
  
  if($format eq 'vcf') {
    $region         =~ s/CHR/chr/gi if($region =~ /^CHR/gi);
    my $vcf_filters = $hub->param('vcf_filters');
    $job_desc       = $hub->param('collection_format') eq 'custom' ? "Data Slicer (VCF Custom file)" : "Data Slicer (VCF ".$hub->param('collection_format').")";
   
    if($vcf_filters eq 'populations') {
      if($hub->param('collection_format') eq 'phase1') {
        $fix_sample_url = $SiteDefs::PHASE1_PANEL_URL;
        $population     = "phase1_populations";
      } elsif ($hub->param('collection_format') eq 'phase3') {
        $fix_sample_url = $region =~ /^y:/gi  ? $SiteDefs::PHASE3_MALE_URL : $SiteDefs::PHASE3_PANEL_URL;
        $population     = $region =~ /^y:/gi  ? "phase3_male_populations"  : "phase3_populations";
      } else {
        $population     = "custom_populations";
      }     
      
      $job_hash->{'sample_panel'}      = $hub->param('collection_format') eq 'custom' ? $hub->param('custom_sample_url') : $fix_sample_url;
      $job_hash->{'population'}        = $hub->param('pop_caption');
      $job_hash->{'population_value'}  = join(',',$hub->param($population)) if($hub->param($population)); #because some populations have long values with comma, separating the caption with the value so that the caption can be used to select the selected value from the front end
    } 
    
    if ($vcf_filters eq 'individuals'){
    
      (my $ind_list = $hub->param('ind_list')) =~ s/\s+//g;
      $job_hash->{'individuals_box'}  = join(',',$hub->param('individuals_box'));
      $job_hash->{'individuals_text'} = $ind_list;
    }
    $job_hash->{'file_url'}     = $hub->param('collection_format') eq 'custom' ? $hub->param('custom_file_url') : $hub->param('generated_file_url');
    $job_hash->{'upload_type'}  = $hub->param('collection_format');
    $job_hash->{'vcf_filters'}  = $hub->param('vcf_filters');
  } else {
    #Bam format
    $job_desc               = "Data Slicer (BAM Custom file)";
    $job_hash->{'file_url'} = $hub->param('bam_file_url');
    $job_hash->{'bai_file'} = $hub->param('bai_file');
  } 

  $self->add_job(EnsEMBL::Web::Job::DataSlicer->new($self, {
    'job_desc'    => $hub->param('name') ? $hub->param('name') : $job_desc,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => {
      'species'         => $species,
      'region'          => $region,
      'job_desc'        => $hub->param('name') ? $hub->param('name') : $job_desc,
      'file_format'     => $format,
      %$job_hash
    }
  }));
}

1;

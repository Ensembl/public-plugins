=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Ticket::VariationPattern;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::VariationPattern;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self    = shift;
  my $hub     = $self->hub;
  my $species = $hub->param('species');
  
  my ($fix_sample_url); 
  if($hub->param('collection_format') eq 'phase1') {
    $fix_sample_url = $SiteDefs::PHASE1_PANEL_URL;    
  }
  
  if ($hub->param('collection_format') eq 'phase3') {
    $fix_sample_url = $hub->param('region') =~ /^y:/gi  ? $SiteDefs::PHASE3_MALE_URL : $SiteDefs::PHASE3_PANEL_URL;
  }
 
  throw exception('InputError', 'No input data is present') unless $hub->param('custom_file_url') || $hub->param('generated_file_url');

  $self->add_job(EnsEMBL::Web::Job::VariationPattern->new($self, {
    'job_desc'    => $hub->param('name') ? $hub->param('name') : $hub->param('collection_format') eq 'custom' ? "Variation pattern finder (Custom file)" : "Variation pattern finder (".$hub->param('collection_format').")",
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => {
      'species'         => $species,
      'job_desc'        => $hub->param('name') ? $hub->param('name') : $hub->param('collection_format') eq 'custom' ? "Variation pattern finder (Custom file)" : "Variaton pattern finder (".$hub->param('collection_format').")",
      'upload_type'     => $hub->param('collection_format'),
      'file_url'        => $hub->param('custom_file_url') ? $hub->param('custom_file_url') : $hub->param('generated_file_url'),
      'sample_panel'    => $hub->param('custom_sample_url') ? $hub->param('custom_sample_url') : $fix_sample_url,
      'region'          => uc($hub->param('region')),
    }
  }));
}

1;

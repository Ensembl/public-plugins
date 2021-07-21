=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Ticket::Postgap;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::Postgap;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self  = shift;

  my $hub           = $self->hub;
  my $species       = $hub->param('species');
  my $method        = first { $hub->param($_) } qw(file url text);
  my $output_format = 'tsv'; #hardcoded for now until we have this optional on the form (can be either tsv or json)

  # if no data entered
  throw exception('InputError', 'No input file has been entered') unless $hub->param('file');

  my ($file_content, $file_name) = $self->get_input_file_content($method);
 
  $self->add_job(EnsEMBL::Web::Job::Postgap->new($self, {
    'job_desc'    => $hub->param('name') ? $hub->param('name') : "Post-GWAS job",
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),    
    'job_data'    => {
      'job_desc'        => $hub->param('name') ? $hub->param('name') : "Post-GWAS job",
      'input_file'      => $file_name,
      'population'      => $hub->param('population') || 'AFR',
      'output_file'     => 'postgap_output',
      'output2_file'    => 'output2.tsv', # this is used by the html report generation script
      'output_format'   => $output_format,
      'report_file'     => 'colocalization_report.html'
    }
  }, {
    $file_name    => {'content' => $file_content}
  }));
}

1;

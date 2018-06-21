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

package EnsEMBL::Web::Component::Tools::DataSlicer::TicketDetails;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::DataSlicer
  EnsEMBL::Web::Component::Tools::TicketDetails
);

sub job_details_table {
  ## @override
  my ($self, $job, $is_owned_ticket) = @_;

  my $object      = $self->object;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $job_data    = $job->job_data;
  my $species     = $job->species;
  my $two_col     = $self->new_twocol;
  my $job_summary = $self->get_job_summary($job, $is_owned_ticket);

  $two_col->add_row('Job name',       $job_summary->render);
  $two_col->add_row('Species',        $object->valid_species($species) ? sprintf('<img class="job-species" src="%sspecies/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1)) : $species =~ s/_/ /rg);
  $two_col->add_row('Assembly',       $job->assembly);
  $two_col->add_row('File format',    $job_data->{file_format});
  $two_col->add_row('Region',         $job_data->{region});
  $two_col->add_row('File URL',       $job_data->{file_url});
  $two_col->add_row('Generate .bai file',  'Y') if($job_data->{bai_file});
  
  if($job_data->{vcf_filters} && ($job_data->{vcf_filters} eq 'individuals' || $job_data->{vcf_filters} eq 'populations')) {
    $two_col->add_row('Filter by',       $job_data->{vcf_filters});
    $job_data->{vcf_filters} eq 'individuals' ? $two_col->add_row('Individual(s)', $job_data->{individuals_box} ? $job_data->{individuals_box} : $job_data->{individuals_text}) : $two_col->add_row('Population(s)', $job_data->{population})
  } else {
    $two_col->add_row('Filter by',       "No filters") if($job_data->{vcf_filters} && $job_data->{vcf_filters} eq 'null');
  }
  
  
  return $two_col;
}

1;

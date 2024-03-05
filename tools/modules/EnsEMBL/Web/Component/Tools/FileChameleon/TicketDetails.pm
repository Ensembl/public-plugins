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

package EnsEMBL::Web::Component::Tools::FileChameleon::TicketDetails;

use strict;
use warnings;

use EnsEMBL::Web::FileChameleonConstants qw(STYLE_FORMATS);

use parent qw(
  EnsEMBL::Web::Component::Tools::FileChameleon
  EnsEMBL::Web::Component::Tools::TicketDetails
);

sub job_details_table {
  ## @override
  my ($self, $job, $is_owned_ticket) = @_;

  my $style_formats = STYLE_FORMATS;
  my $object        = $self->object;
  my $hub           = $self->hub;
  my $sd            = $hub->species_defs;
  my $job_data      = $job->job_data;
  my $species       = $job->species;
  my $two_col       = $self->new_twocol;
  my $job_summary   = $self->get_job_summary($job, $is_owned_ticket);
  (my $long_genes   = $job_data->{long_genes}) =~ s/(0+)/Mbp/gi if($job_data->{long_genes});
  my @filter_value  = grep {$_->{value} eq $job_data->{chr_filter}} @$style_formats; #getting the matching caption for the chromosome naming style value

  $two_col->add_row('Job name',       $job_summary->render);
  $two_col->add_row('Species',        $object->valid_species($species) ? sprintf('<img class="job-species" src="%sspecies/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1)) : $species =~ s/_/ /rg);
  $two_col->add_row('Assembly',       $job->assembly);
  $two_col->add_row('File format',    $job_data->{format});
  $two_col->add_row('Source file',    $job_data->{file_text});
  $two_col->add_row('Chromosome naming style', $filter_value[0]->{caption}) if($job_data->{chr_filter});
  $two_col->add_row('Remove long genes',       ">$long_genes") if($job_data->{long_genes});
  $two_col->add_row('Add transcript IDs',      "Y") if($job_data->{add_transcript});
  $two_col->add_row('Remap patches',           "Y") if($job_data->{remap_patch});
  $two_col->add_row('Output file',    $job->dispatcher_data->{'output_file'}) if($job->dispatcher_data->{'output_file'});

  return $two_col;
}

1;

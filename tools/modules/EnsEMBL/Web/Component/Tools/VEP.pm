=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools);

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @params Extra params as required by get_job_summary method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job) = splice @_, 0, 2;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $species   = $job->species;
  my $sd        = $self->hub->species_defs;
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Job summary',  $self->get_job_summary($job, @_)->render =~ s/Job 0\: //r);
  $two_col->add_row('Species',      sprintf('<img class="job-species" src="%sspecies/16/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1)));

  return $two_col;
}

sub job_statistics {
  ## Gets the job result stats for display on results pages
  my $self    = shift;
  my $file    = $self->object->result_files->{'stats_file'};
  my $stats   = {};
  my $section;

  for (split /\n/, $file->content) {
    if (m/^\[(.+?)\]$/) {
      $section = $1;
    } elsif (m/\w+/) {
      my ($key, $value) = split "\t";
      $stats->{$section}->{$key} = $value;
      push @{$stats->{'sort'}->{$section}}, $key;
    }
  }

  return $stats;
}

1;

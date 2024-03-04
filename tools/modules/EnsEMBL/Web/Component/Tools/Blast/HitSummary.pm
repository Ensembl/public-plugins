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

package EnsEMBL::Web::Component::Tools::Blast::HitSummary;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;

  my $job     = $object->get_requested_job({'with_requested_result' => 1});
  my $result  = $job && $job->status eq 'done' ? $job->result->[0] : undef;
  my $blast   = $object->get_tool_caption;

  if ($result) {

    my $hit   = $result->result_data;
    my $table = $self->new_twocol;

    $table->add_row("$blast type",          $object->parse_search_type($job->job_data->{'search_type'}, 'search_method'));
    $table->add_row('Query location',       sprintf '%s %s to %s (%s)', $hit->{'qid'}, $hit->{'qstart'}, $hit->{'qend'}, $hit->{'qori'} == 1 ? '+' : '-');
    $table->add_row('Database location',    sprintf '%s %s to %s (%s)', $hit->{'tid'}, $hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'} == 1 ? '+' : '-');
    $table->add_row('Genomic location',     sprintf '%s %s to %s (%s)', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}, $hit->{'gori'} == 1 ? '+' : '-');
    $table->add_row('Alignment score',      $hit->{'score'});
    $table->add_row('E-value',              $hit->{'evalue'});
    $table->add_row('Alignment length',     $hit->{'len'});
    $table->add_row('Percentage identity',  $hit->{'pident'});

    return $table->render;
  }

  return $self->no_result_hit_found;
}

sub no_result_hit_found {
  ## Default HTML to be displayed if no hit was found according to the URL params
  return 'No result hit was found according to your request.';# TODO - display button to go back to summary page
}

1;

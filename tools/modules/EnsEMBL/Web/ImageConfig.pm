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

package EnsEMBL::Web::ImageConfig;

### Plugin to core EnsEMBL::Web::ImageConfig to add blast result tracks to the image

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants qw(BLAST_TRACK_PATTERN);

sub initialize_tools_tracks {
  ## Adds the required extra tracks accoridng to the ticket in the url
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $hub->core_object('Tools');

  # create the required Tools object if it's not created by default
  if (!$object && $hub->param('tl')) {
    $object = $hub->new_object('Tools', {}, {'_hub' => $hub});
    $hub->builder->object('Tools', $object) if $object && $hub->builder;
  }

  # display the tools related track if required
  if ($object) {
    my $job     = $object->get_requested_job({'with_all_results' => 1});
    my $results = $job && $job->result || [];

    return unless @$results;

    my $ticket_type = $job->ticket->ticket_type_name;

    if ($ticket_type eq 'Blast') {

      my $ticket    = $object->get_requested_ticket;
      my $species   = $job->species;
      my $jobs      = [ grep { $_->species eq $species && $_->job_id != $job->job_id } @{$ticket->job} ]; # all other jobs for the requested ticket with species same as the selected job

      for ($job, @$jobs) {

        my $desc    = $object->get_job_description($_);
        my $job_id  = $_->job_id;

        $self->add_track('sequence', "blast_$job_id", $desc, 'BlastHit', {
          'description' => $desc,
          'name'        => 'BLAST/BLAT Hit',
          'display'     => 'normal',
          'strand'      => 'b',
          'colourset'   => 'feature',
          'sub_type'    => 'blast',
          'job_id'      => $job_id,
          'main_blast'  => $_ eq $job ? 1 : 0,
          'pattern'     => BLAST_TRACK_PATTERN,
        });
      }

      $self->add_track('information', 'blast_legend', 'BLAST/BLAT Legend', 'BlastHitLegend', {
        'display'     => 'normal',
        'strand'      => 'r',
        'name'        => 'BLAST/BLAT Legend',
        'pattern'     => BLAST_TRACK_PATTERN,
      });

    } elsif ($ticket_type eq 'VEP') {
      $self->add_track('sequence', 'vep_job', 'VEP result', 'VEPSequence', { # TODO - move it to variation menu
        'description' => 'Track displaying sequence variant for the VEP job',
        'display'     => 'normal',
        'strand'      => 'f',
        'colourset'   => 'variation',
        'sub_type'    => 'variant',
      });

    }
  }
}

1;

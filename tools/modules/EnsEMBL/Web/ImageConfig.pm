=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use previous qw(glyphset_configs);

sub has_tools_track {
  ## Tells what type of tool track is present if any
  ## @return Type of tool track (Blast/VEP) or undef if no tool related track is present
  return shift->{'_tools_track'};
}

sub initialize_tools_tracks {
  ## Adds the required extra tracks accoridng to the ticket in the url
  my $self = shift;

  # display the tools related track if required
  if (my $object = $self->hub->core_object('Tools')) {
    my $job     = $object->get_requested_job({'with_all_results' => 1});
    my $results = $job && $job->result || [];

    return unless @$results;

    my $ticket_type = $job->ticket->ticket_type_name;

    if ($ticket_type eq 'Blast') {
      $self->add_track('sequence', 'blast', 'BLAST/BLAT hits', 'BlastHit', {
        'description' => 'Track displaying BLAST/BLAT hits for the selected job',
        'display'     => 'normal',
        'strand'      => 'b',
        'colourset'   => 'feature',
        'sub_type'    => 'blast',
      });

      $self->add_track('information', 'blast_legend', 'BLAST/BLAT Legend', 'BlastHitLegend', {
        'display'     => 'normal',
        'strand'      => 'r',
        'name'        => 'BLAST/BLAT Legend',
      });

      $self->{'_tools_track'} = 'Blast';

    } elsif ($ticket_type eq 'VEP') {
      $self->add_track('sequence', 'vep_job', 'VEP result', 'VEPSequence', { # TODO - move it to variation menu
        'description' => 'Track displaying sequence variant for the VEP job',
        'display'     => 'normal',
        'strand'      => 'f',
        'colourset'   => 'variation',
        'sub_type'    => 'variant',
      });

      $self->{'_tools_track'} = 'VEP';
    }
  }
}

sub blast_glyphset_configs {
  ## This plugin adds multiple blast tracks depending upon the number of jobs we have in the current ticket
  my $self = shift;

  if (!$self->{'_ordered_tracks_blast'}) {

    my $tracks  = $self->PREV::glyphset_configs(@_);

    return $tracks unless ($self->has_tools_track || '') eq 'Blast';

    my $object    = $self->hub->core_object('Tools');
    my $ticket    = $object->get_requested_ticket;
    my $jobs      = $ticket->job; # all jobs for the requested ticket
    my $selected  = $object->parse_url_param->{'job_id'}; # id of the selected job

    return $tracks if @$jobs == 1; # we already have a track added for one job

    my @tracks = map {

      my @t = $_;

      if ($_->id eq 'blast') {

        push @t, map { $_->job_id eq $selected ? () : $self->_clone_track($t[0]) } @$jobs;

        for (0..$#t) {
          my $desc    = $object->get_job_description($jobs->[$_]);
          my $job_id  = $jobs->[$_]->job_id;

          $t[$_]->set('job_id',           $job_id);
          $t[$_]->set('main_blast_track', $selected eq $job_id);
          $t[$_]->set('caption',          $desc);
          $t[$_]->set('name',             sprintf '%s: %s', $t[$_]->get('name'), $desc);
          $t[$_]->set('description',      $desc);
          $t[$_]->set('sub_type',         sprintf 'blast_%s', $job_id);
        }

        @t = sort { $b->get('job_id') eq $selected ? 1 : 0 } @t; # bring the selected job closer to the contig
        @t = reverse @t if $_->get('drawing_strand') eq 'f';
      }

      @t;

    } @$tracks;

    $self->{'_ordered_tracks_blast'} = \@tracks;
  }

  return $self->{'_ordered_tracks_blast'};
}

1;

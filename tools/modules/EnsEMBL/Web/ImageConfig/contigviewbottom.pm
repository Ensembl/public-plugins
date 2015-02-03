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

package EnsEMBL::Web::ImageConfig::contigviewbottom;

### Plugin to core EnsEMBL::Web::ImageConfig::contigviewbottom to add blast result tracks to the image

use strict;
use warnings;

use previous qw(initialize);

sub initialize {
  ## @plugin
  ## Adds blast and VEP tracks to the config according the the ticket in the url
  my $self = shift;
  $self->PREV::initialize(@_);
  $self->initialize_tools_tracks;
}

sub glyphset_configs {
  ## This plugin adds multiple blast tracks depending upon the number of jobs we have in the current ticket
  my $self    = shift;

  if (!$self->{'_ordered_tracks_blast'}) {

    my $tracks  = $self->SUPER::glyphset_configs(@_);

    return $tracks unless ($self->has_tools_track || '') eq 'Blast';

    my $object  = $self->hub->core_object('Tools');
    my $ticket  = $object->get_requested_ticket;
    my $jobs    = $ticket->job; # all jobs for the requested ticket
    my $job_id  = $object->parse_url_param->{'job_id'}; # id of the selected job

    return $tracks if @$jobs == 1; # we already have a track added for one job

    my @tracks = map {

      my @t = $_;

      if ($_->id eq 'blast') {
        my @clones = map {
          my $clone = $_->job_id eq $job_id ? undef : $self->_clone_track($t[0]);
          $clone->set('job_id', $_->job_id) if $clone;
          $clone || ();
        } @$jobs;

        $_->set('job_id', $job_id);
        $_->set('main_blast_track', 1);

        push @t, @clones;

        @t = reverse @t if $_->get('drawing_strand') eq 'f';
      }

      @t;

    } @$tracks;

    $self->{'_ordered_tracks_blast'} = \@tracks;
  }

  return $self->{'_ordered_tracks_blast'};
}

1;

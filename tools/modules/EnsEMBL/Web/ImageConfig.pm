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

      $self->add_track('information', 'blast_legend', 'BLAST/BLAT Legend', 'HSP_legend', {
        'display'     => 'normal',
        'strand'      => 'r',
        'name'        => 'BLAST/BLAT Legend',
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

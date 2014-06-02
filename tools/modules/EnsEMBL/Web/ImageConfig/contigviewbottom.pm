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

package EnsEMBL::Web::ImageConfig::contigviewbottom;

### Plugin to core EnsEMBL::Web::ImageConfig::contigviewbottom to add blast result tracks to the image

use strict;
use warnings;

use previous qw(init);

sub init {
  ## @plugin
  ## Adds blast track to the config
  my $self = shift;
  $self->PREV::init(@_);

  # display the blast track if required
  if (my $object = $self->hub->core_object('Tools')) {
    $object   = $object->get_sub_object('Blast');
    my $job   = $object->get_requested_job({'with_all_results' => 1});

    if ($job && @{$job->result}) {
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
    }
  }
}

1;

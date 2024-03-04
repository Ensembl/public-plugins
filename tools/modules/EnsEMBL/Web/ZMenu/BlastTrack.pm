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

package EnsEMBL::Web::ZMenu::BlastTrack;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ZMenu::Blast);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object->get_sub_object('Blast');
  my $job           = $object->get_requested_job({'with_requested_result' => 1});
  my $job_data      = $job->job_data;
  my $species       = $job->species;
  my @results       = $job->result; # although returned an array, it will only be one result object as asked for in the url
  my $blast_type    = $object->parse_search_type($job_data->{'search_type'}, 'blast_type') eq 'BLAT' ? 'BLAT' : 'BLAST';

  for (@results) {
    $self->add_hit_content($job, $_, $blast_type);
    $self->add_entry({
      'label' => 'Go to results page',
      'link'  => $hub->url({'type' => 'Tools', 'action' => 'Blast', 'function' => 'Results', 'tl' => $object->create_url_param})
    });
    last;
  }
}

1;

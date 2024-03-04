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

package EnsEMBL::Web::Component::Tools::Blast::HspQueryPlot;

use strict;
use warnings;

use EnsEMBL::Draw::DrawableContainer;
use EnsEMBL::Web::Document::Image::GD;
use EnsEMBL::Web::Container::HSPContainer;

use EnsEMBL::Web::BlastConstants qw(BLAST_KARYOTYPE_POINTER);

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object;
  my $job           = $object->get_requested_job({'with_all_results' => 1});
  my $results       = $job && $job->status eq 'done' ? $job->result : [];
  my @pointer_cols  = $hub->colourmap->build_linear_gradient(@{BLAST_KARYOTYPE_POINTER->{'gradient'}});

  return '' unless @$results;

  # Draw the HSP image
  my $image                   = EnsEMBL::Web::Document::Image::GD->new($hub, $self);
  $image->drawable_container  = EnsEMBL::Draw::DrawableContainer->new(EnsEMBL::Web::Container::HSPContainer->new($object, $job, \@pointer_cols), $hub->get_imageconfig('hsp_query_plot'));
  $image->imagemap            = 'yes';
  $image->set_button('drag');

  # final HTML
  return sprintf('
    <h3><a rel="_blast_queryplot" class="toggle _slide_toggle set_cookie closed" href="#">HSP distribution on query sequence</a></h3>
    <div class="_blast_queryplot toggleable hidden">%s</div>',
    $image->render,
  );
}

1;

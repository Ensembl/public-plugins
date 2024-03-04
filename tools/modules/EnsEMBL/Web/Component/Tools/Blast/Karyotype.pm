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

package EnsEMBL::Web::Component::Tools::Blast::Karyotype;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants qw(BLAST_KARYOTYPE_POINTER);

use parent qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $sd        = $hub->species_defs;
  my $job       = $object->get_requested_job({'with_all_results' => 1});

  return '' if !$job || $job->status ne 'done' || !$job->result_count;

  my $species     = $job->species;
  my $chromosomes = $sd->get_config($species, 'ENSEMBL_CHROMOSOMES') || [];

  return '' unless @$chromosomes && $sd->MAX_CHR_LENGTH;

  my $image_config  = $hub->get_imageconfig('Vkaryoblast');
  my $image         = $self->new_karyotype_image($image_config);
  $image->{'export'} = 1;

  my $pointers      = $self->get_hit_pointers($job, $image);

  $image->caption   = 'Click on the image above to jump to a chromosome, or click and drag to select a region';
  $image->imagemap  = 'yes';
  $image->set_button('drag', 'title' => 'Click on a chromosome');
  $image->karyotype($hub, $object, $pointers, 'Vkaryoblast');

  return if $self->_export_image($image,'no_text');

  return sprintf('
    <h3><a rel ="_blast_karyotype" class="toggle _slide_toggle set_cookie open" href="#">HSP distribution on genome</a></h3>
    <div class="_blast_karyotype">
      <div class="toggleable">%s</div>
    </div>',
    $image->render
  );
}

sub get_hit_pointers {
  my ($self, $job, $image) = @_;

  my $object        = $self->object;
  my $hub           = $self->hub;
  my $pointer_spec  = BLAST_KARYOTYPE_POINTER;
  my $features      = $object->map_result_hits_to_karyotype($job);

  my $pointers      = [ $image->add_pointers($hub, {
    'config_name'     => 'Vkaryoblast',
    'features'        => $features,
    'feature_type'    => 'Xref',
    'style'           => $pointer_spec->{'style'},
    'color'           => $pointer_spec->{'colour'},
    'gradient'        => $pointer_spec->{'gradient'},
  }) ];

  if ($pointer_spec->{'style'} ne $pointer_spec->{'high_score_style'}) {
    my $top_feature = $features->[0];
    delete $top_feature->{'href'}; # no duplicate zmenu for highest score hit
    push @$pointers, $image->add_pointers($hub, {
      'config_name'   => 'Vkaryoblast',
      'features'      => [ $top_feature ],
      'feature_type'  => 'Xref',
      'style'         => $pointer_spec->{'high_score_style'},
      'color'         => $pointer_spec->{'colour'},
      'gradient'      => $pointer_spec->{'gradient'},
    });
  }

  return $pointers;
}

1;

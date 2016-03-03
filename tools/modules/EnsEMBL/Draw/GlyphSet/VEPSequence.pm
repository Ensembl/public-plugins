=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet::VEPSequence;

## VEP sequence track for contigviewbottom

use strict;
use warnings;

use Bio::EnsEMBL::Variation::VariationFeature;
use Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor;

use parent qw(EnsEMBL::Draw::GlyphSet::_variation);

sub features {
  my $self = shift;

  my $object      = $self->{'config'}->hub->core_object('Tools') or return;
     $object      = $object->get_sub_object('VEP');
  my $job         = $object->get_requested_job({'with_all_results' => 1}) or return;
  my $slice       = $self->{'container'};
  my $start       = $slice->start;
  my $strand      = $self->strand;
  my @variants    = grep $strand eq $_->{'strand'}, @{$object->get_all_variants_in_slice_region($job, $slice)};
  my $fnum        = scalar @variants;
  my $calc_type   = $fnum > 200 ? 0 : 1;
  my $species     = $slice->adaptor->db->species;
  my @features;

  # Can we actually draw this many features?
  unless ($calc_type) {
    return 'too_many';
  }

  my $vfa = Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor->new_fake($species);

  for (@variants) {

    my ($vstart, $vend) = $_->{'start'} < $_->{'end'} ? ($_->{'start'}, $_->{'end'}) : ($_->{'end'}, $_->{'start'});
    $vend   = $vend - $vstart;
    $vstart = $vstart - $start + 1;
    $vend   = $vstart + $vend;

    my $snp = bless {
      'start'             => $vstart,
      'end'               => $vend,
      'map_weight'        => 1,
      'adaptor'           => $vfa,
      'slice'             => $slice,
      'strand'            => $_->{'strand'},
      'allele_string'     => $_->{'allele_string'},
      'variation_name'    => $_->{'variation_name'},
      'consequence_type'  => [ $_->{'consequence_type'} ],
      'tl'                => $_->{'tl'}
    }, 'Bio::EnsEMBL::Variation::VariationFeature';

    push @features, $snp;

    $self->{'legend'}{'variation_legend'}{$snp->display_consequence} ||= $self->get_colour($snp);
  }

  return $self->{'_cache'}{'features'} = \@features;
}

sub href {
  my ($self, $f)  = @_;

  return $self->_url({
    species   => $self->species,
    type      => 'Variation',
    action    => 'VEP',
    v         => $f->variation_name,
    config    => $self->{'config'}{'type'},
    track     => $self->type,
    tl        => $f->{'tl'}
  });
}


1;

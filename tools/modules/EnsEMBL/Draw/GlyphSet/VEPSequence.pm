=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

use parent qw(EnsEMBL::Draw::GlyphSet::variation);

sub get_data {
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

  # Can we actually draw this many features?
  unless ($calc_type) {
    $self->errorTrack("Cannot display more than 200 variants");
    return [];
  }

  my $features;
  my $colour_lookup = {};

  for (@variants) {

    my ($vstart, $vend) = $_->{'start'} < $_->{'end'} ? ($_->{'start'}, $_->{'end'}) : ($_->{'end'}, $_->{'start'});
    $vend   = $vend - $vstart;
    $vstart = $vstart - $start + 1;
    $vend   = $vstart + $vend;

    my $snp = {
      'start'             => $vstart,
      'end'               => $vend,
      'strand'            => $_->{'strand'},
      'label'             => $_->{'variation_name'},
      'href'              => $self->href($_),
      'colour_key'        => $_->{'consequence_type'},
    };

    ## Set colour and do legend
    my $key = $snp->{'colour_key'};
    $colour_lookup->{$key} ||= $self->get_colours($snp);
    my $colour = $self->{'legend'}{'variation_legend'}{$key} ||= $colour_lookup->{$key}{'feature'};
    $snp->{'colour'}        = $colour;
    $snp->{'colour_lookup'} = $colour_lookup->{$key};
    $self->{'legend'}{'variation_legend'}{$key} ||= $colour;

    push @$features, $snp;
  }

  return [{'features' => $features}]; 
}

sub href {
  my ($self, $f, $tl)  = @_;

  return $self->_url({
    species   => $self->species,
    type      => 'Tools',
    action    => 'VEP',
    v         => $f->{'variation_name'},
    config    => $self->{'config'}{'type'},
    track     => $self->type,
    tl        => $f->{'tl'}
  });
}


1;

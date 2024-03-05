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

package EnsEMBL::Web::ViewConfig::Blast::AlignmentProtein;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init_cacheable {
  ## @override
  my $self = shift;
  
  $self->SUPER::init_cacheable(@_);
  
  $self->set_default_options({
    display_width  => 60,
    align_display  => 'line',
    snp_display    => 'off',
    line_numbering => 'yes',
    exon_display   => 'yes',
  });
}

sub form_fields {}
sub field_order {}

sub init_form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'display_width',
    label  => 'Number of amino acids per row',
    values => [
      map {{ value => $_, name => "$_ aa" }} map 10*$_, 3..20
    ]    
  });
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'align_display',
    label  => 'Alignments display',
    values => [
      { value => 'off',  'name' => 'Off'},
      { value => 'line', 'name' => 'Mark matching bp with lines'},
      { value => 'dot',  'name' => 'Mark matching bp with dots' }
    ]
  });
  
  $self->add_form_element({ type => 'YesNo', name => 'exon_display', select => 'select', label => 'Show exons' });
  $self->variation_options({ populations => [ 'fetch_all_HapMap_Populations', 'fetch_all_1KG_Populations' ], snp_link => 'no' }) if $self->species_defs->databases->{'DATABASE_VARIATION'};
  $self->add_form_element({ type => 'YesNo', name => 'line_numbering', select => 'select', label => 'Number residues' });
}

1;

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

package EnsEMBL::Web::ViewConfig::Blast::QuerySeq;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init_cacheable {
  my $self = shift;
  
  $self->SUPER::init_cacheable(@_);
  
  $self->set_default_options({
    display_width  => 60,
    hsp_display    => 'all',
    line_numbering => 'slice',
  });
  
  $self->title('BLAST/BLAT Query Sequence');
}

sub form_fields {}
sub field_order {}

sub init_form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'hsp_display',
    label  => 'Alignment Markup',
    values => [
      { value => 'all', name => 'All alignments' },
      { value => 'sel', name => 'Selected alignments only' },
      { value => 'off', name => 'No alignment markup' }
    ],
  });
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'line_numbering',
    label  => 'Line numbering',
    values => [
      { value => 'slice', name => 'Relative to this sequence' },
      { value => 'off',   name => 'None' }
    ],
  });
}

1;

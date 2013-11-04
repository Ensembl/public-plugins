package EnsEMBL::Web::ViewConfig::Blast::QuerySeq;

use strict;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self  = shift;
  
  $self->SUPER::init;
  
  $self->set_defaults({
    display_width  => 60,
    hsp_display    => 'all',
    line_numbering => 'slice',
  });
  
  $self->title = 'BLAST/BLAT Query Sequence';
}

sub form {
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

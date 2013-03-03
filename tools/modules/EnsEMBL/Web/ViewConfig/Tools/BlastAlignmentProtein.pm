package EnsEMBL::Web::ViewConfig::Tools::BlastAlignmentProtein;

use strict;

use EnsEMBL::Web::Constants;
use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'}||{};

  $self->SUPER::init;

  $self->set_defaults({
      display_width   => 60,
      align_display   => 'line',
      snp_display     => 'off',
      line_numbering  => 'no',
      exon_display    => 'yes',
  });

}

sub form {
  my $self = shift;

  $self->add_form_element({
    type   => 'DropDown',
    select => 'select',
    name   => 'display_width',
    label  => 'Number of amino acids per row',
    values => [
      map {{ value => $_, name => "$_ aa" }} map 10*$_, 3..20
    ]    
  });

  $self->add_form_element({
    type    => 'DropDown',
    select  => 'select',
    name    => 'align_display',
    label   => 'Alignments display',
    values  => [
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

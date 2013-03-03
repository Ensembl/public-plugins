package EnsEMBL::Web::ViewConfig::Tools::BlastAlignment;

use strict;

use EnsEMBL::Web::Constants;
use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'}||{};

  $self->SUPER::init;

  $self->set_defaults({
      display_width   => 60,
      line_numbering  => 'off',
      align_display   => 'line',
      snp_display     => 'no',
      exon_display    => 'core',
      exon_ori        => 'off',
      codons_display  => 'off',
  });
}

sub form {
  my $self = shift;

  my %gene_markup_options    = EnsEMBL::Web::Constants::GENE_MARKUP_OPTIONS;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS;      
  my %other_markup_options = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;
  push @{$general_markup_options{'exon_ori'}{'values'}}, { value => 'off', name => 'None' };
  my $dbs  = $self->species_defs->databases;

  $self->add_form_element($other_markup_options{'display_width'});
  $self->add_form_element($general_markup_options{'line_numbering'});
  $self->add_form_element($gene_markup_options{'exon_display'}); 
  $self->add_form_element($general_markup_options{'exon_ori'});
  $self->add_form_element($other_markup_options{'codons_display'});


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

  $self->variation_options if $dbs->{'DATABASE_VARIATION'};
}
1;




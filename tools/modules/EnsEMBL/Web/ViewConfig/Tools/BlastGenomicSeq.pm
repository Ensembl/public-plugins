package EnsEMBL::Web::ViewConfig::Tools::BlastGenomicSeq;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  my $sp         = $self->species;
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'}||{};  

  $self->SUPER::init;
  
  $self->set_defaults({
    flank5_display    => 300,
    flank3_display    => 300,
    display_width     => 60,
    hsp_display       => 'all',
    exon_ori          => 'all',
    match_display     => 'off',
    snp_display       => 'off',
    line_numbering    => 'slice',
    codons_display    => 'off',
    title_display     => 'off',
    orientation       => 'fa',
  });

  $self->title  = 'BLAST Genomic Sequence';
}

sub form {
  my $self = shift;
  my %gene_markup_options    = EnsEMBL::Web::Constants::GENE_MARKUP_OPTIONS;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS; # shared with compara_markup and marked-up sequence
  my %other_markup_options   = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;   # shared with compara_markup
  my $dbs  = $self->species_defs->databases;

  push @{$general_markup_options{'exon_ori'}{'values'}}, { value => 'off', name => 'None' };
  $general_markup_options{'exon_ori'}{'label'} = 'Exons to highlight';

  $self->add_form_element($other_markup_options{'display_width'});
  $self->add_form_element($gene_markup_options{'flank5_display'});
  $self->add_form_element($gene_markup_options{'flank3_display'});

  $self->add_form_element({
    type    => 'DropDown',
    select  => 'select',
    name    => 'orientation',
    label   => 'Orientation',
    values  => [
      { value => 'fc', name => 'Forward relative to coordinate system' },
      { value => 'rc', name => 'Reverse relative to coordinate system' },
      { value => 'fa', name => 'Forward relative to selected alignment' }
    ]
  });

  $self->add_form_element({
    type    => 'DropDown',
    select  => 'select',
    name    => 'hsp_display',
    label   => 'Alignment Markup',
    values  => [
      { value => 'all', name => 'All alignments' },
      { value => 'sel', name => 'Selected alignments only' },
      { value => 'off', name => 'No alignment markup' }
    ],
  });

  $self->add_form_element($general_markup_options{'exon_ori'});
=cut
  $self->add_form_element({
    type     => 'DropDown',
    select   => 'select',
    name     => 'match_display',
    label    => 'Display Matches',
    values   => [
      { value => 'off', name => 'Show all' },
      { value => 'dot', name => 'Replace matching bp with dots' },
      { value => 'line', name => 'Display Homology line'}
    ]
  });
=cut
  $self->variation_options if $dbs->{'DATABASE_VARIATION'};
  $self->add_form_element($general_markup_options{'line_numbering'});
  $self->add_form_element($other_markup_options{'codons_display'});
  $self->add_form_element($other_markup_options{'title_display'});
}

1;

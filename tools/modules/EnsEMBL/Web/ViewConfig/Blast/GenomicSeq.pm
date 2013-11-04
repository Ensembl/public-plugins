package EnsEMBL::Web::ViewConfig::Blast::GenomicSeq;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  
  $self->SUPER::init;
  
  $self->set_defaults({
    flank5_display => 300,
    flank3_display => 300,
    display_width  => 60,
    hsp_display    => 'all',
    exon_display   => 'core',
    exon_ori       => 'all',
    snp_display    => 'off',
    line_numbering => 'slice',
    title_display  => 'yes',
    orientation    => 'fa',
  });
  
  $self->title = 'BLAST Genomic Sequence';
}

sub form {
  my $self                   = shift;
  my $dbs                    = $self->species_defs->databases;
  my %gene_markup_options    = EnsEMBL::Web::Constants::GENE_MARKUP_OPTIONS;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS; # shared with compara_markup and marked-up sequence
  my %other_markup_options   = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;   # shared with compara_markup
  
  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'vega',          name => 'Vega exons'     } if $dbs->{'DATABASE_VEGA'};
  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'otherfeatures', name => 'EST gene exons' } if $dbs->{'DATABASE_OTHERFEATURES'};
  
  $self->add_form_element($other_markup_options{'display_width'});
  $self->add_form_element($gene_markup_options{'flank5_display'});
  $self->add_form_element($gene_markup_options{'flank3_display'});
  
  $self->add_form_element({
    type   => 'dropdown',
    select => 'select',
    name   => 'orientation',
    label  => 'Orientation',
    values => [
      { value => 'fc', name => 'Forward relative to coordinate system' },
      { value => 'rc', name => 'Reverse relative to coordinate system' },
      { value => 'fa', name => 'Forward relative to selected alignment' }
    ]
  });
  
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
  
  $self->add_form_element({ %{$gene_markup_options{'exon_display'}}, label => 'Show exons' });
  $self->add_form_element({ %{$general_markup_options{'exon_ori'}},  label => 'Orientation of exons' });
  $self->variation_options if $dbs->{'DATABASE_VARIATION'};
  $self->add_form_element($general_markup_options{'line_numbering'});
  $self->add_form_element($other_markup_options{'title_display'});
}

1;

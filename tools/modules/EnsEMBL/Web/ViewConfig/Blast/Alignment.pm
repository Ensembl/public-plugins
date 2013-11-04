package EnsEMBL::Web::ViewConfig::Blast::Alignment;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  
  $self->SUPER::init;
  
  $self->set_defaults({
    display_width  => 60,
    align_display  => 'line',
    exon_display   => 'core',
    exon_ori       => 'all',
    snp_display    => 'off',
    line_numbering => 'off',
    title_display  => 'yes',
  });
}

sub form {
  my $self                   = shift;
  my $dbs                    = $self->species_defs->databases;
  my %gene_markup_options    = EnsEMBL::Web::Constants::GENE_MARKUP_OPTIONS;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS;
  my %other_markup_options   = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;
  
  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'vega',          name => 'Vega exons'     } if $dbs->{'DATABASE_VEGA'};
  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'otherfeatures', name => 'EST gene exons' } if $dbs->{'DATABASE_OTHERFEATURES'};
  
  $self->add_form_element($other_markup_options{'display_width'});
  
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
  
  $self->add_form_element({ %{$gene_markup_options{'exon_display'}}, label => 'Show exons' });
  $self->add_form_element({ %{$general_markup_options{'exon_ori'}},  label => 'Orientation of exons' });
  $self->variation_options({ populations => [ 'fetch_all_HapMap_Populations', 'fetch_all_1KG_Populations' ], snp_link => 'no' }) if $dbs->{'DATABASE_VARIATION'};
  $self->add_form_element($general_markup_options{'line_numbering'});
  $self->add_form_element($other_markup_options{'title_display'});
}

1;

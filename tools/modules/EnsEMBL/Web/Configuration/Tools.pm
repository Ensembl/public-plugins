package EnsEMBL::Web::Configuration::Tools;

use strict;

use EnsEMBL::Web::RegObj;

use base qw( EnsEMBL::Web::Configuration );

sub global_context { return $_[0]->_global_context; }
sub ajax_content   { return $_[0]->_ajax_content;   }
sub configurator   { return $_[0]->_configurator;   }
sub local_context  { return $_[0]->_local_context;  }
sub local_tools    { return $_[0]->_local_tools;    }
sub content_panel  { return $_[0]->_content_panel;  }
sub context_panel  { return undef;  }

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Blast';
}

sub caption {
  return 'Tools';
}

sub short_caption {
  return 'Tools';
}

sub populate_tree {
  my $self = shift;

  $self->create_node('Summary', 'Activity Summary',
    [qw( 
      summary   EnsEMBL::Web::Component::Tools::JobsList 
      details   EnsEMBL::Web::Component::Tools::TicketDetails          
    )],
    { 'availability' => 1, 'concise' => 'Activity Summary' }
  );
  $self->create_node('Blast', 'BLAST/BLAT search',
    [qw(
      jobs         EnsEMBL::Web::Component::Tools::JobsList 
      sequence     EnsEMBL::Web::Component::Tools::BlastInputForm
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT search' }
  );

  my $blast_node = $self->tree->get_node('Blast');
  $blast_node->append($self->create_subnode('BlastResults', 'Results',
    [qw(
      karyotype   EnsEMBL::Web::Component::Tools::Karyotype
      hsps        EnsEMBL::Web::Component::Tools::HspQueryPlot
      results     EnsEMBL::Web::Component::Tools::BlastResults
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT results' } 
  ));
  $blast_node->append($self->create_subnode('BlastAlignment', 'Alignment',
    [qw(
      hit       EnsEMBL::Web::Component::Tools::BlastHitSummary
      alignment     EnsEMBL::Web::Component::Tools::BlastAlignment
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => 1 }
  ));
  $blast_node->append($self->create_subnode('BlastAlignmentProtein', 'Alignment',
    [qw(
      hit       EnsEMBL::Web::Component::Tools::BlastHitSummary
      alignment     EnsEMBL::Web::Component::Tools::BlastAlignmentProtein
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => 1 }
  ));
  $blast_node->append($self->create_subnode('BlastQuerySeq', 'Query Sequence',
    [qw(
      hit       EnsEMBL::Web::Component::Tools::BlastHitSummary
      query     EnsEMBL::Web::Component::Tools::BlastQuerySeq
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT Query Sequence', 'no_menu_entry' => 1 }
  ));
  $blast_node->append($self->create_subnode('BlastGenomicSeq', 'Genomic Sequence',
    [qw(
      hit       EnsEMBL::Web::Component::Tools::BlastHitSummary
      genomic     EnsEMBL::Web::Component::Tools::BlastGenomicSeq
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT Genomic Sequence', 'no_menu_entry' => 1 }
  ));

  $self->create_node( 'Submit', '', [],
    {'command' => 'EnsEMBL::Web::Command::Tools::Submit',
     'availability' => 1, 'no_menu_entry' => 1 },
  );
  $self->create_node( 'Download', 'Download', 
    [qw( download EnsEMBL::Web::Component::Tools::Download )],
    { 'availability' => 1, 'no_menu_entry' => 1 },
  );
=cut
  my $custom_tracks_menu = $self->create_submenu('custom', 'Custom tracks');
  $custom_tracks_menu->append($self->create_node('Upload', 'Upload a file',
    [qw( upload         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'Upload a file' }
  ));
  $custom_tracks_menu->append($self->create_node('UrlData', 'Attach URL data',
    [qw( url         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'Attach URL data' }
  ));
  $custom_tracks_menu->append($self->create_node('DAS', 'Attach a DAS source',
    [qw( das         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'Attach DAS source' }
  ));
=cut
  my $data_conversion_menu = $self->create_submenu('convert', 'Data Conversion');
  $data_conversion_menu->append($self->create_node('AssemblyConverter', 'Assembly converter',
    [qw( assembly         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'Assembly Converter' }
  ));
  $data_conversion_menu->append($self->create_node('IDMapper', 'ID History Converter',
    [qw( idhistory         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'ID History Converter' }
  ));
  $data_conversion_menu->append($self->create_node('VEP', 'Variation Effect Predictor',
    [qw( vepeffect         EnsEMBL::Web::Component::Tools::Blank )],
    { 'availability' => 1, 'concise' => 'VEP' }
  ));

}

sub user_populate_tree {
  my $self = shift;

}

1;


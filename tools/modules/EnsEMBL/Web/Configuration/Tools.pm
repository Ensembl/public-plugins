package EnsEMBL::Web::Configuration::Tools;

use strict;
use warnings;

use base qw( EnsEMBL::Web::Configuration );

sub modify_page_elements  { $_[0]->page->remove_body_element('summary');  }
sub set_default_action    { $_[0]->{'_data'}{'default'} = 'Summary';      }

sub populate_tree {
  my $self = shift;

  my $tools_node = $self->create_node('Summary', 'Web Tools',
    [qw(
      icons           EnsEMBL::Web::Component::Tools::Icons
      tickets         EnsEMBL::Web::Component::Tools::TicketsList
    )],
    { 'availability' => 1, 'concise' => 'Web Tools' }
  );

  $tools_node->append($_) for (

    ## BLAST specific nodes
    $self->create_subnode('Blast', 'BLAST/BLAT',
      [qw(
        tickets         EnsEMBL::Web::Component::Tools::Blast::TicketsList
        sequence        EnsEMBL::Web::Component::Tools::Blast::InputForm
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT search' }
    ),
    $self->create_subnode('Blast/Summary', 'Activity Summary',
      [qw(
        tickets         EnsEMBL::Web::Component::Tools::Blast::TicketsList
        details         EnsEMBL::Web::Component::Tools::Blast::TicketDetails
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Activity Summary', 'no_menu_entry' => 1 }
    ),
    $self->create_subnode('Blast/Results', 'Results',
      [qw(
        results         EnsEMBL::Web::Component::Tools::Blast::JobDetails
        karyotype       EnsEMBL::Web::Component::Tools::Blast::Karyotype
        hsps            EnsEMBL::Web::Component::Tools::Blast::HspQueryPlot
        table           EnsEMBL::Web::Component::Tools::Blast::ResultsTable
      )],
      { 'availability' => 1, 'concise' => $self->object ? $self->object->long_caption : '', 'no_menu_entry' => 1 }
    ),
    $self->create_subnode('Blast/Alignment', 'Alignment',
      [qw(
        hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
        alignment       EnsEMBL::Web::Component::Tools::Blast::Alignment
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => 1 }
    ),
    $self->create_subnode('Blast/AlignmentProtein', 'AlignmentProtein',
      [qw(
        hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
        alignment       EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => 1 }
    ),
    $self->create_subnode('Blast/QuerySeq', 'Query Sequence',
      [qw(
        hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
        query           EnsEMBL::Web::Component::Tools::Blast::QuerySeq
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Query Sequence', 'no_menu_entry' => 1 }
    ),
    $self->create_subnode('Blast/GenomicSeq', 'Genomic Sequence',
      [qw(
        hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
        genomic         EnsEMBL::Web::Component::Tools::Blast::GenomicSeq
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Genomic Sequence', 'no_menu_entry' => 1 }
    ),

    ## VEP specific nodes
    $self->create_subnode('VEP', 'Variation Effect Predictor',
      [qw(
        jobs         EnsEMBL::Web::Component::Tools::TicketsList
        vepeffect    EnsEMBL::Web::Component::Tools::VEP::InputForm
      )],
      { 'availability' => 1, 'concise' => 'Variation Effect Predictor<span style="float:right;"><img src="/img/vep_logo.png"></span>' }
    ),
    $self->create_subnode('VEP/Summary', 'Results',
      [qw(
        ressummary  EnsEMBL::Web::Component::Tools::VEP::ResultsSummary
        results     EnsEMBL::Web::Component::Tools::VEP::Results
      )],
      { 'availability' => 1, 'concise' => 'Variant Effect Predictor results<span style="float:right"><img src="/img/vep_logo.png"></span>', 'no_menu_entry' => 1 } 
    )
  );
}

1;

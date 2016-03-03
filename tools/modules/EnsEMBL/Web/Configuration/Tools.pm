=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Tools;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Configuration);

sub modify_page_elements  { $_[0]->page->remove_body_element('summary');  }
sub set_default_action    { $_[0]->{'_data'}{'default'} = 'Summary';      }
sub tree_cache_key        { return undef; } # don't cache tree as it contains user specific tickets etc

sub populate_tree {
  my $self        = shift;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $action      = $hub->action || '';
  my $function    = $hub->function || '';
  my $object      = $self->object && $self->object->get_sub_object;
  my $url_param   = $object && $object->parse_url_param;
  my $job         = $object && $object->get_requested_job;
  my $result_cap  = $job ? $object->get_job_description($job) : 'Results';

  my $tools_node  = $self->create_node('Summary', 'Web Tools',
    [qw(
      icons           EnsEMBL::Web::Component::Tools::Icons
      tickets         EnsEMBL::Web::Component::Tools::TicketsList
    )],
    { 'availability' => 1, 'concise' => 'Web Tools' }
  );

  if ($sd->ENSEMBL_BLAST_ENABLED) {

    my $blast_node = $tools_node->append($self->create_subnode('Blast', 'BLAST/BLAT',
      [qw(
        sequence        EnsEMBL::Web::Component::Tools::Blast::InputForm
        details         EnsEMBL::Web::Component::Tools::Blast::TicketDetails
        tickets         EnsEMBL::Web::Component::Tools::Blast::TicketsList
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT search' }
    ));

    # Flags to display blast nodes and sub-nodes
    my $hide_result           = $action ne 'Blast' || $function !~ /^(Results|Alignment(Protein)?|(Genomic|Query)Seq)$/;
    my $hide_ticket           = "$action/$function" ne 'Blast/Ticket' && $hide_result;
    my $hide_sub_result_nodes = "$action/$function" eq 'Blast/Results';
    my $alignment_type        = $job && $object->can('get_alignment_component_name_for_job') ? $object->get_alignment_component_name_for_job($job) : '';

    my $blast_ticket_node = $blast_node->append($self->create_subnode('Blast/Ticket', 'Ticket',
      [qw(
        tickets         EnsEMBL::Web::Component::Tools::Blast::TicketsList
      )],
      { 'availability' => 1, 'concise' => 'BLAST/BLAT Ticket', 'no_menu_entry' => $hide_ticket }
    ));

    my $blast_results_node = $blast_ticket_node->append($self->create_subnode('Blast/Results', $result_cap,
      [qw(
        details         EnsEMBL::Web::Component::Tools::Blast::TicketDetails
        results         EnsEMBL::Web::Component::Tools::Blast::ResultsSummary
        table           EnsEMBL::Web::Component::Tools::Blast::ResultsTable
        karyotype       EnsEMBL::Web::Component::Tools::Blast::Karyotype
        hsps            EnsEMBL::Web::Component::Tools::Blast::HspQueryPlot
      )],
      { 'availability' => 1, 'concise' => $object ? $object->long_caption : '', 'no_menu_entry' => $hide_result }
    ));

    $blast_results_node->append($_) for (

      ## BLAST specific nodes
      $self->create_subnode('Blast/Alignment', 'Alignment',
        [qw(
          hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
          alignment       EnsEMBL::Web::Component::Tools::Blast::Alignment
        )],
        { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => $hide_sub_result_nodes || $alignment_type ne 'Alignment'}
      ),
      $self->create_subnode('Blast/AlignmentProtein', 'Alignment',
        [qw(
          hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
          alignment       EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein
        )],
        { 'availability' => 1, 'concise' => 'BLAST/BLAT Alignment', 'no_menu_entry' => $hide_sub_result_nodes || $alignment_type ne 'AlignmentProtein'}
      ),
      $self->create_subnode('Blast/QuerySeq', 'Query Sequence',
        [qw(
          hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
          query           EnsEMBL::Web::Component::Tools::Blast::QuerySeq
        )],
        { 'availability' => 1, 'concise' => 'BLAST/BLAT Query Sequence', 'no_menu_entry' => $hide_sub_result_nodes }
      ),
      $self->create_subnode('Blast/GenomicSeq', 'Genomic Sequence',
        [qw(
          hit             EnsEMBL::Web::Component::Tools::Blast::HitSummary
          genomic         EnsEMBL::Web::Component::Tools::Blast::GenomicSeq
        )],
        { 'availability' => 1, 'concise' => 'BLAST/BLAT Genomic Sequence', 'no_menu_entry' => $hide_sub_result_nodes }
      )
    );

    ## Extra blast results
    for (!$hide_result && $job ? $job->ticket->job : ()) {
      my $job_id = $_->job_id;

      next unless $_->result_count;

      # keep the order of jobs preserved
      if ($job->job_id eq $job_id) {
        $blast_ticket_node->append($blast_results_node);
        next;
      }

      $blast_ticket_node->append($self->create_subnode("Blast/Results/$job_id", $object->get_job_description($_), [], {
        'availability'  => 1,
        'raw'           => 1,
        'url'           => $hub->url({qw(type Tools action Blast function Results), 'tl' => $object->create_url_param({'job_id' => $job_id})})
      }));
    }
  }

  ## VEP specific nodes
  if ($sd->ENSEMBL_VEP_ENABLED) {
    my $vep_node = $tools_node->append($self->create_subnode('VEP', 'Variant Effect Predictor',
      [qw(
        vepeffect       EnsEMBL::Web::Component::Tools::VEP::InputForm
        details         EnsEMBL::Web::Component::Tools::VEP::TicketDetails
        tickets         EnsEMBL::Web::Component::Tools::VEP::TicketsList
      )],
      { 'availability' => 1, 'concise' => 'Variant Effect Predictor' }
    ));

    $vep_node->append($self->create_subnode('VEP/Results', $result_cap,
      [qw(
        details     EnsEMBL::Web::Component::Tools::VEP::TicketDetails
        ressummary  EnsEMBL::Web::Component::Tools::VEP::ResultsSummary
        results     EnsEMBL::Web::Component::Tools::VEP::Results
      )],
      { 'availability' => 1, 'concise' => 'Variant Effect Predictor results', 'no_menu_entry' => "$action/$function" ne 'VEP/Results' }
    ));
  }

  ## Assembly converter specific node (doesn't need results page, just a download of file from ticket details)
  if ($sd->ENSEMBL_AC_ENABLED) {
    my $ac_node = $tools_node->append($self->create_subnode('AssemblyConverter', 'Assembly Converter',
      [qw(
        ac_input        EnsEMBL::Web::Component::Tools::AssemblyConverter::InputForm
        ac_details      EnsEMBL::Web::Component::Tools::AssemblyConverter::TicketDetails
        tickets         EnsEMBL::Web::Component::Tools::AssemblyConverter::TicketsList
      )],
      { 'availability' => 1 }
    ));
  }

  ## ID History converter specific node
  if ($sd->ENSEMBL_IDM_ENABLED) {
    my $idmapper_node = $tools_node->append($self->create_subnode('IDMapper', 'ID History Converter',
      [qw(
        idhc_input      EnsEMBL::Web::Component::Tools::IDMapper::InputForm
        idhc_details    EnsEMBL::Web::Component::Tools::IDMapper::TicketDetails
        tickets         EnsEMBL::Web::Component::Tools::IDMapper::TicketsList
      )],
      { 'availability' => 1 }
    ));

    $idmapper_node->append($self->create_subnode('IDMapper/Results', $result_cap,
      [qw(
        details     EnsEMBL::Web::Component::Tools::IDMapper::TicketDetails
        ressummary  EnsEMBL::Web::Component::Tools::IDMapper::ResultsSummary
        results     EnsEMBL::Web::Component::Tools::IDMapper::Results
      )],
      { 'availability' => 1, 'concise' => 'ID History Converter results', 'no_menu_entry' => "$action/$function" ne 'IDMapper/Results' }
    ));
  }

}

1;

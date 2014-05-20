=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use parent qw( EnsEMBL::Web::Configuration );

sub modify_page_elements  { $_[0]->page->remove_body_element('summary');  }
sub set_default_action    { $_[0]->{'_data'}{'default'} = 'Summary';      }

sub populate_tree {
  my $self        = shift;
  my $hub         = $self->hub;
  my $action      = $hub->action || '';
  my $function    = $hub->function || '';
  my $object      = $self->object && $self->object->get_sub_object;
  my $url_param   = $object && $object->parse_url_param;
  my $job         = $object && $object->get_requested_job;
  my $result_cap  = $url_param && $url_param->{'ticket_name'} && $url_param->{'job_id'} ? "Results ($url_param->{'ticket_name'}/$url_param->{'job_id'})" : 'Results';

  my $tools_node  = $self->create_node('Summary', 'Web Tools',
    [qw(
      icons           EnsEMBL::Web::Component::Tools::Icons
      tickets         EnsEMBL::Web::Component::Tools::TicketsList
    )],
    { 'availability' => 1, 'concise' => 'Web Tools' }
  );

  my $blast_node = $tools_node->append($self->create_subnode('Blast', 'BLAST/BLAT',
    [qw(
      sequence        EnsEMBL::Web::Component::Tools::Blast::InputForm
      details         EnsEMBL::Web::Component::Tools::Blast::TicketDetails
      tickets         EnsEMBL::Web::Component::Tools::TicketsList
    )],
    { 'availability' => 1, 'concise' => 'BLAST/BLAT search' }
  ));

  my $blast_results_node = $blast_node->append($self->create_subnode('Blast/Results', $result_cap,
    [qw(
      results         EnsEMBL::Web::Component::Tools::Blast::ResultsSummary
      karyotype       EnsEMBL::Web::Component::Tools::Blast::Karyotype
      hsps            EnsEMBL::Web::Component::Tools::Blast::HspQueryPlot
      table           EnsEMBL::Web::Component::Tools::Blast::ResultsTable
    )],
    { 'availability' => 1, 'concise' => $object ? $object->long_caption : '', 'no_menu_entry' => "$action/$function" !~ /^Blast\/(Results|Alignment(Protein)?|(Genomic|Query)Seq)$/ }
  ));

  # Flags to display blast result sub-nodes
  my $hide_sub_result_nodes = "$action/$function" eq 'Blast/Results';
  my $alignment_type        = $job && $object->can('get_alignment_component_name_for_job') ? $object->get_alignment_component_name_for_job($job) : '';

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

  ## VEP specific nodes
  my $vep_node = $tools_node->append($self->create_subnode('VEP', 'Variant Effect Predictor',
    [qw(
      vepeffect       EnsEMBL::Web::Component::Tools::VEP::InputForm
      details         EnsEMBL::Web::Component::Tools::VEP::TicketDetails
      tickets         EnsEMBL::Web::Component::Tools::TicketsList
    )],
    { 'availability' => 1, 'concise' => 'Variant Effect Predictor' }
  ));

  $vep_node->append($self->create_subnode('VEP/Results', $result_cap,
    [qw(
      ressummary  EnsEMBL::Web::Component::Tools::VEP::ResultsSummary
      results     EnsEMBL::Web::Component::Tools::VEP::Results
    )],
    { 'availability' => 1, 'concise' => 'Variant Effect Predictor results', 'no_menu_entry' => "$action/$function" ne 'VEP/Results' }
  ));

}

1;

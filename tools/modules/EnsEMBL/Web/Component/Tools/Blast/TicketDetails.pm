=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::TicketDetails;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);

use parent qw(
  EnsEMBL::Web::Component::Tools::Blast
  EnsEMBL::Web::Component::Tools::TicketDetails
);

sub content_ticket {
  ## Abstract method implementation
  my ($self, $ticket, $jobs, $is_owned_ticket) = @_;
  my $hub     = $self->hub;
  my $div     = $self->dom->create_element('div');
  my $is_view = $self->view_type eq 'View';

  $div->set_attribute('class', 'plain-box') if $is_view;

  for (@$jobs) {
    my $job_table = $self->job_details_table($_, $is_owned_ticket);
    if (!$is_view) {
      $job_table->append_child('div', {
        'class'     => [qw(_ticket_details hidden toggleable)], # this div is hidden by default
        'children'  => [ splice @{$job_table->child_nodes}, 4 ] # first four rows should always stay on
      });
    }
    $div->append_child($job_table);
  }

  return $div->render;
}

sub job_details_table {
  ## @override
  my ($self, $job, $is_owned_ticket) = @_;

  my $object      = $self->object;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $job_data    = $job->job_data;
  my $job_num     = $job->job_number;
  my $species     = $job->species;
  my $configs     = $self->_display_config($job_data->{'configs'});
  my $two_col     = $self->new_twocol;
  my $sequence    = $object->get_input_sequence_for_job($job);
  my $job_summary = $self->get_job_summary($job, $is_owned_ticket);

  $two_col->add_row('Job name',       $job_summary->render);
  $two_col->add_row('Species',        $object->valid_species($species) ? sprintf('<img class="job-species" src="%sspecies/%s.png" alt="" height="16" width="16">%s', $self->img_url, $species, $sd->species_label($species, 1)) : $species =~ s/_/ /rg);
  $two_col->add_row('Assembly',       $job->assembly);
  $two_col->add_row('Search type',    $object->get_param_value_caption('search_type', $job_data->{'search_type'}));
  $two_col->add_row('Sequence',       sprintf('<div class="input-seq">&gt;%s</div>', join("\n", $sequence->{'display_id'} || '', ($sequence->{'sequence'} =~ /.{1,60}/g))));
  $two_col->add_row('Query type',     $object->get_param_value_caption('query_type', $job_data->{'query_type'}));
  $two_col->add_row('DB type',        $object->get_param_value_caption('db_type', $job_data->{'db_type'}));
  $two_col->add_row('Source',         $object->get_param_value_caption('source', $job_data->{'source'}));
  $two_col->add_row('Configurations', $configs) if $configs;

  return $two_col;
}

sub _display_config {
  ## @private
  my ($self, $configs) = @_;
  my $fields  = CONFIGURATION_FIELDS;
  my $two_col = $self->new_twocol;

  $two_col->set_attribute('class', 'blast-configs');

  while (my ($config_type, $config_fields) = splice @$fields, 0, 2) {

    my @rows = [ sprintf('<b>%s options</b>', ucfirst $config_type =~ s/_/ /gr), '' ];

    while (my ($field_name, $field_details) = splice @{$config_fields->{'fields'}}, 0, 2) {
      if (exists $configs->{$field_name}) {
        my ($value) = exists $field_details->{'commandline_values'}
          ? ucfirst $configs->{$field_name} # since the value for this field is set according to 'commandline_values'
          : map { $_->{'value'} eq $configs->{$field_name} ? $_->{'caption'} : () } @{$field_details->{'values'}} # otherwise choose the right 'caption' key from the 'values' arrayref that hash a matching 'value' key
        ;
        push @rows, [ $field_details->{'label'}, $value // '' ];
      }
    }

    $two_col->add_rows(@rows) if @rows > 1;
  }

  return $two_col->is_empty ? '' : $two_col->render;
}

1;

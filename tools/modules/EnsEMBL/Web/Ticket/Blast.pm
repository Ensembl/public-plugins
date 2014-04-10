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

package EnsEMBL::Web::Ticket::Blast;

use strict;
use warnings;

use Bio::SeqIO;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::Blast;
use EnsEMBL::Web::BlastConstants qw(MAX_SEQUENCE_LENGTH CONFIGURATION_FIELDS CONFIGURATION_DEFAULTS);

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self  = shift;
  my @jobs  = $self->_process_user_input;

  throw exception('InputError', 'Form validation failed.') unless @jobs; # this is just a backup generic message, since actual validation before reaching this point has already been done on the frontend.

  $self->add_job(EnsEMBL::Web::Job::Blast->new($self, $_)) for @jobs;
}

sub _process_user_input {
  ## @private
  ## Validates the inputs, then create set of parameters for each job, ready to be submitted
  ## Returns undefined if any of the parameters (other than sequences/species) are invalid (no specific message is returned since all validations were done at the frontend first - if input is still invalid, someone's just messing around)
  my $self      = shift;
  my $object    = $self->object;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $params    = {};

  # Validate Species
  my @species = $sd->valid_species($hub->param('species'));
  return unless @species;

  # Validate Query Type, DB Type, Source Type and Search Type
  for (qw(query_type db_type source search_type)) {
    my $param_value = $params->{$_} = $hub->param($_);
    return unless $param_value && $object->get_param_value_caption($_, $param_value); #get_param_value_caption returns undef if value is invalid
  }

  # process the extra configurations
  $params->{'configs'} = $self->_process_extra_configs($params->{'search_type'});
  return unless $params->{'configs'};

  # Process input sequences
  my $input_seqs  = join "\n\n", $self->param('sequence');
  my $file_handle = FileHandle->new(\$input_seqs, 'r');
  my $seq_io      = Bio::SeqIO->new('-fh' => $file_handle, '-alphabet' => $params->{'query_type'} eq 'peptide' ? 'protein' : 'dna', '-format' => 'fasta');
  my $seq_objects = [];

  while (my $seq_object = $seq_io->next_seq) {
    my $is_invalid  = $seq_object->validate_seq ? 0 : 1;
    my $seq_string  = $seq_object->seq;
    $is_invalid     = sprintf 'Sequence contains more than %s characters', MAX_SEQUENCE_LENGTH if !$is_invalid && length $seq_string > MAX_SEQUENCE_LENGTH;
    push @$seq_objects, {
      'display_id'  => $seq_object->display_id,
      'seq'         => $seq_string,
      'is_invalid'  => $is_invalid
    };
  }
  $file_handle->close;

  # Create parameter sets for individual jobs to be submitted (submit one job per sequence per species)
  my $jobs      = [];
  my $desc      = $self->param('description');
  my $prog      = $self->parse_search_type($params->{'search_type'}, 'search_method');
  my $db_types  = $sd->multi_val('ENSEMBL_BLAST_DB_TYPES');
  my $job_num   = 0;
  for my $species (@species) {
    my $i = 0;
    for my $seq_object (@$seq_objects) {
      push @$jobs, {
        'job_number'  => ++$job_num,
        'job_desc'    => $desc || sprintf('%s search against %s %s.', $prog, $sd->get_config($species, 'SPECIES_COMMON_NAME'), $db_types->{$params->{'db_type'}}),
        'species'     => $species,
        'sequence'    => $seq_object,
        'source_file' => $sd->get_config($species, 'ENSEMBL_BLAST_CONFIGS')->{$params->{'query_type'}}{$params->{'db_type'}}{$params->{'search_type'}}{$params->{'source'}},
        %$params
      };
    }
  }

  return $jobs;
}

sub _process_extra_configs {
  ## @private
  ## Gets all the extra configs from CGI depending upon the selected search type
  ## @param Search type string
  ## @return Hashref of config params, or undef in case of validation error
  my ($self, $search_type_value) = @_;

  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
  my $config_values   = {};

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    while (my ($element_name, $element_params) = splice @$config_field_group, 0, 2) {

      for ($search_type_value, 'all') {
        if (exists $config_defaults->{$_}{$element_name}) {

          my $element_value = $self->param("${search_type_value}__${element_name}") // '';

          return unless grep {$_ eq $element_value} map($_->{'value'}, @{$element_params->{'values'}}), $element_params->{'type'} eq 'checklist' ? '' : (); # checklist is also allowed to have null value

          if (($element_params->{'commandline_type'} || '') eq 'flag') {
            $config_values->{$element_name} = '' if $element_value;
          } else {
            $config_values->{$element_name} = exists $element_params->{'commandline_values'} ? $element_params->{'commandline_values'}{$element_value} : $element_value;
          }

          last;
        }
      }
    }
  }

  return $config_values;
}

1;
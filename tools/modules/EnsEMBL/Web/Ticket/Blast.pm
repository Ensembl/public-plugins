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

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::Blast;
use EnsEMBL::Web::BlastConstants qw(MAX_SEQUENCE_LENGTH CONFIGURATION_FIELDS CONFIGURATION_DEFAULTS SEQUENCE_VALID_CHARS);

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self  = shift;
  my $jobs  = $self->_process_user_input;

  throw exception('InputError', 'Form validation failed.') unless $jobs; # this is just a generic message, since actual validation before reaching this point has already been done on the frontend.

  $self->add_job(EnsEMBL::Web::Job::Blast->new($self, @$_)) for @$jobs;
}

sub _process_user_input {
  ## @private
  ## Validates the inputs, then create set of parameters for each job, ready to be submitted
  ## Returns undefined if any of the parameters (other than sequences/species) are invalid (no specific message is returned since all validations were done at the frontend first - if input is still invalid, someone's just messing around)
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $params      = {};
  my $valid_chars = SEQUENCE_VALID_CHARS;

  # Validate Species
  my @species = $sd->valid_species($hub->param('species'));
  return unless @species;

  # Source param depends upon the selected db type
  $hub->param('source', $hub->param('source_'.$hub->param('db_type')));

  # Validate Query Type, DB Type, Source Type and Search Type
  for (qw(query_type db_type source search_type)) {
    my $param_value = $params->{$_} = $hub->param($_);
    return unless $param_value && $object->get_param_value_caption($_, $param_value); #get_param_value_caption returns undef if value is invalid
  }

  # Process the extra configurations
  $params->{'configs'} = $self->_process_extra_configs($params->{'search_type'});
  return unless $params->{'configs'};

  # Process and validate input sequences
  my $sequences = [];
  for ($hub->param('sequence')) {

    next if ($_ // '') eq '';

    my @seq_lines = split /\R/, $_;
    my $fasta     = $seq_lines[0] =~ /^>/ ? [ shift @seq_lines ] : [ '>' ];
    my $sequence  = join '', @seq_lines;

    # Rebuild fasta with 60 chars column length
    push @$fasta, $1 while $sequence =~ m/(.{1,60})/g;

    push @$sequences, {
      'fasta'       => join("\n", @$fasta),
      'display_id'  => $fasta->[0] =~ s/^>\s*//r,
      'is_invalid'  => $sequence =~ m/^[$valid_chars]*$/
        ? (length $sequence <= MAX_SEQUENCE_LENGTH)
        ? 0
        : sprintf('Sequence contains more than %s characters', MAX_SEQUENCE_LENGTH)
        : sprintf('Sequence contains invalid characters (%s)', join('', ($sequence =~ m/[^$valid_chars]/g)))
    };
  }
  return unless @$sequences;

  # Create parameter sets for individual jobs to be submitted (submit one job per sequence per species)
  my ($blast_type, $search_method)  = $object->parse_search_type($params->{'search_type'});
  my $desc                          = $hub->param('description');
  my $source_types                  = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES');
  my $jobs                          = [];
  my $job_num                       = 0;

  for my $species (@species) {

    for my $sequence (@$sequences) {

      my $summary = sprintf('%s against %s (%s)', $search_method, $sd->get_config($species, 'SPECIES_COMMON_NAME'), $source_types->{$params->{'source'}});

      push @$jobs, [ {
        'job_number'  => ++$job_num,
        'job_desc'    => $desc || $sequence->{'display_id'} || $summary,
        'species'     => $species,
        'assembly'    => $sd->get_config($species, 'ASSEMBLY_NAME'),
        'job_data'    => {
          'output_file' => 'blast.out',
          'sequence'    => {
            'input_file'  => 'input.fa',
            'is_invalid'  => $sequence->{'is_invalid'}
          },
          'summary'     => $summary,
          'source_file' => $sd->get_config($species, 'ENSEMBL_BLAST_DATASOURCES')->{$blast_type}{$params->{'source'}},
          %$params
        }
      }, {
        'input.fa'    => {
          'content'     => $sequence->{'fasta'}
        }
      } ];
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

  my $hub = $self->hub;

  my $config_fields   = CONFIGURATION_FIELDS;
  my $config_defaults = CONFIGURATION_DEFAULTS;
  my $config_values   = {};

  while (my ($config_type, $config_field_group) = splice @$config_fields, 0, 2) {

    while (my ($element_name, $element_params) = splice @$config_field_group, 0, 2) {

      for ($search_type_value, 'all') {
        if (exists $config_defaults->{$_}{$element_name}) {

          my $element_value = $hub->param("${search_type_value}__${element_name}") // '';

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

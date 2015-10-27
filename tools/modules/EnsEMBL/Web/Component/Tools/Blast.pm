=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast;

### Base class for all Blast components

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);

use parent qw(EnsEMBL::Web::Component::Tools);

sub no_result_hit_found {
  ## Default HTML to be displayed if no hit was found according to the URL params
  return 'No result hit was found according to your request.';# TODO - display button to go back to summary page
}

sub job_status_tag {
  ## @override
  ## Add info about number of hits found to the status tag if job's done
  my ($self, $job, $status, $hits, $result_url, $assembly_mismatch, $has_assembly_site) = @_;

  my $tag = $self->SUPER::job_status_tag($job, $status, $hits, $result_url, $assembly_mismatch, $has_assembly_site);

  if ($status eq 'done') {
    $tag->{'inner_HTML'} .= sprintf ': %s hit%s found', $hits || 'No', $hits == 1 ? '' : 's';

    if (!$hits && !$assembly_mismatch) {
      $tag->{'class'} = [ 'job-status-noresult', grep { $_ ne 'job-status-done' } @{$tag->{'class'}} ];
      $tag->{'title'} = 'This job is finished, but no hits were found. If you believe that there should be a match to your query sequence please edit the job using the icon on the right to adjust the configuration parameters and resubmit the search.';
      $tag->{'href'}  = '';
    }
  }

  return $tag;
}

sub _display_config {
  ## @private
  my ($self, $configs) = @_;
  my $fields  = CONFIGURATION_FIELDS;
  my $two_col = $self->new_twocol;

  $two_col->set_attribute('class', 'blast-configs');

  while (my ($config_type, $config_fields) = splice @$fields, 0, 2) {

    my @rows = [ sprintf('<b>%s options</b>', ucfirst $config_type =~ s/_/ /gr), '' ];

    while (my ($field_name, $field_details) = splice @$config_fields, 0, 2) {
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

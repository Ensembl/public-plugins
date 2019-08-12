=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Postgap::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::Postgap
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  return shift->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'});
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self    = shift;
  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my $object  = $self->object;
  my $form    = $self->new_tool_form;
  my $species = $object->species_list;

  # Input fieldset
  my $input_fieldset = $form->add_fieldset({'no_required_notes' => 1});

  # Set species to human only
  $input_fieldset->add_field({
    'label'         => 'Species',
    'elements'      => [{
      'type'          => 'noedit',
      'value'         => sprintf('<img class="job-species" src="%sspecies/Homo_sapiens.png" alt="" height="16" width="16">%s', $self->img_url,$sd->species_label("Homo_sapiens", 1)),
      'no_input'      => 1,
      'is_html'       => 1
    }, {
      'type'          => 'noedit',
      'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
      'no_input'      => 1,
      'is_html'       => 1      
    }, {
      'type'          => 'string',
      'name'          => 'species',
      'size'          => 30,
      'value'         => (map { sprintf ('%s', $_->{'value'}) } @$species),
      'class'         => 'hidden'
    }]
  });

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'IDMapper'} / 1048576)
  });

  # Run/Close buttons
  $self->add_buttons_fieldset($form);

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  return 'PostgapForm';
}


1;

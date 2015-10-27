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

package EnsEMBL::Web::Component::Tools::InputForm;

### Parent class for tools InputForm
### Shall be used with MI

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::File::Tools;

sub form_header_info :Abstract {
  ## Gets the HTML to be displayed above the form
  ## @return HTML string
}

sub get_cacheable_form_node :Abstract {
  ## Gets the form tree node
  ## This method returns the form object that can be cached once and then used for all requests (ie. it does not contian species specific or user specific fields)
  ## @return EnsEMBL::Web::Form object
}

sub get_non_cacheable_fields :Abstract {
  ## Replace placeholders for non-cacheable fields with actual HTML
  ## @return Hashref with each key as a placeholder string in the cached form and value as a hashref to be passed to Fieldset::add_field method
}

sub cache_key {
  ## Returns cache key to be used to save/retrieve form
  ## @return String
  return sprintf '%s::%s', shift->object->tool_type, 'FORM'
}

sub js_panel {
  ## Returns the name of the js panel to be used to initialise the JavaScript on this form
  ## @return String
  return 'ToolsForm';
}

sub js_params {
  ## Returns parameters to be passed to JavaScript panel
  ## @return Hashref of keys to value - if value is hash or array, it gets passed as JSON object
  my $self    = shift;
  my $hub     = $self->hub;
  my $params  = {};

  # URL to load tickets with a placeholder to be replaced with actual ticket id
  $params->{'load_ticket_url'} = $hub->url('Json', {'function' => 'load_ticket', 'tl' => 'TICKET_NAME'}),

  # Previous job params for JavaScript
  my $edit_job = ($hub->function || '') eq 'Edit' ? $self->object->get_edit_jobs_data : [];
  if (@$edit_job) {
    $params->{'edit_jobs'} = $edit_job;
  }

  # Current species
  $params->{'species'} = $self->current_species;

  return $params;
}

sub new_ticket_button_title {
  ## Returns the title to be used on the button that opens form for new job
  ## @return String
  return 'New job';
}

sub current_species {
  ## Gets the current species name for which the form should be displayed
  ## @return String species name
  my $self = shift;

  if (!$self->{'_current_species'}) {
    my $hub     = $self->hub;
    my $species = $hub->species;
       $species = $hub->get_favourite_species->[0] if $species =~ /multi|common/i;

    $self->{'_current_species'} = $species;
  }

  return $self->{'_current_species'};
}

sub new_tool_form {
  ## Creates a new Form object with the information required by all Tools based form pages
  ## Shall be called inside get_cacheable_form_node to get empty form node before adding more fields to it
  ## @param Hashref as provided to Form constructor (optional)
  my ($self, $params) = @_;

  $params ||= {};
  $params->{'class'} = '_tool_form bgcolour '.($params->{'class'} || '');

  my $form = $self->new_form({
    'action'          => $self->hub->url('Json', {'type' => 'Tools', 'action' => $self->object->tool_type, 'function' => 'form_submit'}),
    'method'          => 'post',
    'skip_validation' => 1,
    %$params
  });

  return $form;
}

sub add_buttons_fieldset {
  ## Adds the genetic buttons fieldset to the tools form
  ## Shall be called inside get_cacheable_form_node to add buttons to the form
  ## @param Form object
  ## @param Hashref of keys as the name of the extra links needed ('reset' and 'cancel') and value their caption
  ## @return The added fieldset object
  my ($self, $form, $params) = @_;

  my $url       = $self->hub->url({'function' => ''});
  my $fieldset  = $form->add_fieldset;
  my $field     = $fieldset->add_field({
    'type'            => 'submit',
    'value'           => 'Run &rsaquo;'
  });
  my @extras    = (exists $params->{'reset'} ? {
    'node_name'       => 'a',
    'href'            => $url,
    'class'           => [qw(_tools_form_reset left-margin _change_location)],
    'inner_HTML'      => $params->{'reset'}
  } : (), exists $params->{'cancel'} ? {
    'node_name'       => 'a',
    'href'            => $url,
    'class'           => [qw(_tools_form_cancel left-margin _change_location)],
    'inner_HTML'      => $params->{'cancel'}
  } : ());

  $field->elements->[-1]->append_children(@extras) if @extras;

  return $fieldset;
}

sub files_dropdown {
  ## Gets params for the dropdown to select one of the previously uploaded files
  ## @note Avoid overriding this in child class
  ## @param Arrayref of required formats (each format as a hashref with value and caption for the format)
  ## @return Hashref as accepted by Fieldset->add_field or undef if no files are found
  my ($self, $formats) = @_;

  my $hub     = $self->hub;
  my $sd      = $hub->species_defs;
  my %formats = map { $_->{'value'} => $_->{'caption'} } @$formats;
  my @files   = sort { $b->{'timestamp'} <=> $a->{'timestamp'} } grep { $_->{'format'} && $formats{$_->{'format'}} } $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  return unless @files;

  my @options = { 'value' => '', 'caption' => '-- Select file --'};

  for (@files) {

    my $file = EnsEMBL::Web::File::Tools->new('hub' => $hub, 'tool' => $self->object->tool_type, 'file' => $_->{'file'});
    my @file_data;

    try {
      @file_data = @{$file->read_lines->{'content'}};
    } catch {};

    next unless @file_data;

    my $first_line  = first { $_ !~ /^\#/ } @file_data;
       $first_line  = substr($first_line, 0, 30).'&#8230;' if $first_line && length $first_line > 31;

    push @options, {
      'value'   => $_->{'code'},
      'caption' => sprintf('%s | %s | %s | %s',
        $file->read_name,
        $formats{$_->{'format'}},
        $sd->species_label($_->{'species'}, 1),
        $first_line || '-'
      )
    };
  }

  return unless @options > 1;

  return {
    'type'    => 'dropdown',
    'name'    => 'userdata',
    'label'   => 'Or select previously uploaded file',
    'values'  => \@options,
  };
}

sub content {
  ## Returns the actual content of the component
  ## @note It should not be required to override this in child classes
  my $self      = shift;
  my $hub       = $self->hub;
  my $cache     = $hub->cache;
  my $cache_key = $self->cache_key;
  my $form      = $cache && $cache_key ? $cache->get($cache_key) : undef;

  # If cached form not found, generate a new form and save in cache to skip the form generation process next time
  if (!$form) {
    $form = $self->get_cacheable_form_node->render;
    $cache->set($cache_key, $form) if $cache && $cache_key;
  }

  # Replace any placeholders for non cacheable fields with actual HTML
  $self->_add_non_cacheable_fields(\$form, $self->get_non_cacheable_fields);

  # Pass the js params to the panel
  my $js_params       = $self->js_params || {};
  my $js_params_html  = '';
  for (keys %$js_params) {
    my $is_json = ref $js_params->{$_};
    $js_params_html .= sprintf '<input type="hidden" class="js_param%s" name="%s" value="%s" />', $is_json ? ' json' : '', $self->html_encode($_), $self->html_encode($is_json ? $self->jsonify($js_params->{$_}) : $js_params->{$_});
  }

  return sprintf('<div class="hidden _tool_new"><p><a class="button _change_location" href="%s">%s</a></p></div><div class="hidden _tool_form_div"><input type="hidden" class="panel_type" value="%s" />%s%s%s</div>',
    $hub->url({'function' => ''}),
    $self->new_ticket_button_title,
    $self->js_panel,
    $js_params_html,
    $self->form_header_info,
    $form
  );
}

sub _add_non_cacheable_fields {
  ## @private
  my ($self, $form_ref, $fields) = @_;

  # Add the non-cacheable fields to this dummy form and replace the placeholders from the actual form HTML
  my $fieldset = $self->new_form->add_fieldset;

  $fields->{$_} &&= $fieldset->add_field($fields->{$_}) for keys %$fields;

  $fieldset->prepare_to_render;

  # Regexp to replace all placeholders from cached form
  for (keys %$fields) {
    my $html = $fields->{$_} ? $fields->{$_}->render : '';
    $$form_ref =~ s/$_/$html/e;
  }
}

1;

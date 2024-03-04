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

package EnsEMBL::Web::Component::Tools::InputForm;

### Parent class for tools InputForm
### Shall be used with MI
### If adding a new tool, only override the first few methods listed

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

  #creating a hash for mapping web species name to species production name (e.g: Mus_musculus_129s1_svimj -> mus_musculus_129s1svimj)
  my %speciesname_mapping           = map { $_ =>  $self->hub->species_defs->get_config($_,'SPECIES_PRODUCTION_NAME') } $self->hub->species_defs->valid_species;
  $params->{'speciesname_mapping'}  = \%speciesname_mapping;

  return $params;
}

sub new_ticket_button_title {
  ## Returns the title to be used on the button that opens form for new job
  ## @return String
  return 'New job';
}

sub cache_key {
  ## Returns cache key to be used to save/retrieve form
  ## @note Avoid overriding this in child class
  ## @return String
  return sprintf '%s::%s', shift->object->tool_type, 'FORM'
}

sub current_species {
  ## Gets the current species name for which the form should be displayed
  ## @note Avoid overriding this in child class
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
  ## @note Avoid overriding this in child class
  ## @param Hashref as provided to Form constructor (optional)
  my ($self, $params) = @_;

  $params ||= {};  
  $params->{'class'} = '_tool_form bgcolour '.($params->{'class'} || '');

  my $form = $self->new_form({
    'action'          => $self->hub->url('Json', {'type' => 'Tools', 'action' => $self->object->tool_type, 'function' => 'form_submit'}),
    'method'          => 'post',
    %$params
  });

  return $form;
}

sub tool_header {
  my ($self, $params) = @_;
  
  my $url  = $self->hub->url({'function' => ''});  
  my $html = '<div class="tool-header">New job';
  
  if(exists $params->{'cancel'}) {
    $html .= '<a href="'.$url.'" class="_tools_form_cancel left-margin _change_location">'.$params->{'cancel'}.'</a><span class="right-button">|</span>';
  }  
  if(exists $params->{'reset'}) {
    $html .= '<a href="'.$url.'" class="_tools_form_reset left-margin _change_location">'.$params->{'reset'}.'</a>';
  }
  
  $html .= '</div>';  

  return $html;  
}

sub add_buttons_fieldset {
  ## Adds the genetic buttons fieldset to the tools form
  ## Shall be called inside get_cacheable_form_node to add buttons to the form
  ## @note Avoid overriding this in child class
  ## @param Form object
  ## @param Hashref of keys as the name of the extra links needed ('reset' and 'cancel') and value their caption
  ## @return The added fieldset object
  my ($self, $form, $params) = @_;

  my $url       = $self->hub->url({'function' => ''});
  my $fieldset  = $form->add_fieldset;
  my $field     = $fieldset->add_field({
    'type'            => 'submit',
    'class'           => 'run_button',
    'element_class'   => 'run_container',
    'value'           => 'Run &rsaquo;'
  });

  return $fieldset;
}

sub togglable_fieldsets {
  ## Adds a fieldset/group of fieldsets to a togglable div with a button on top that toggles it
  ## @param Parent form object
  ## @param Hashref with following keys
  ##  - class Class attribute for the wrapping div
  ##  - title Text displayed on the button
  ##  - desc  Extra information displayed on the right side of the button
  ## @params List of fieldsets to be added to the togglable div
  ## @return Config wrapper div object
  my ($self, $form, $options) = splice @_, 0, 3;

  my $togglable_key = $options->{'title'} =~ s/\W+/_/gr;
  my $open          = $options->{'open'} ? "open" : "closed";
  my $hidden        = $options->{'open'} ? "" : "hidden";

  my $wrapper = $form->append_child('div', {
    'class'       => $options->{'class'} || [],
    'children'    => [{
      'node_name'   => 'div',
      'class'       => 'extra_configs_button',
      'children'    => [{
        'node_name'   => 'a',
        'rel'         => "__togg_$togglable_key",
        'class'       => ["_slide_toggle", "toggle", "set_cookie", $open],
        'href'        => "#$togglable_key",
        'inner_HTML'  => $options->{'title'}
      }, {
        'node_name'   => 'span',
        'class'       => 'extra_configs_info',
        'inner_HTML'  => $options->{'desc'}
      }]
    }, {
      'node_name'   => 'div',
      'class'       => "extra_configs __togg_$togglable_key toggleable $hidden",
    }]
  });

  $wrapper->last_child->append_children(@_);
  $wrapper->set_attribute('class', 'extra_configs_wrapper');

  return $form->append_child($wrapper);
}

sub species_specific_info {
  ## Creates an info box alternative assembly info
  ## @param Species
  ## @param Tools type caption
  ## @param Tool type url name
  ## @return HTML for info box to be displayed
  my ($self, $species, $caption, $tool_type, $msg_only) = @_;
  my $hub   = $self->hub;
  my $sd    = $hub->species_defs;
  if (my $alt_assembly = $sd->get_config($species, 'SWITCH_ASSEMBLY')) {
    my $alt_assembly_url    = $sd->get_config($species, 'SWITCH_ARCHIVE_URL');
    my $species_display_name = $sd->get_config($species, 'SPECIES_DISPLAY_NAME');
    my $msg = 
      sprintf('If you are looking for %s for %s %s, please go to <a href="http://%s%s">%3$s website</a>.',
        $caption,
        $species_display_name,
        $alt_assembly,
        $alt_assembly_url,
        $hub->url({'__clear' => 1, 'species' => $species, 'type' => 'Tools', 'action' => $tool_type })
      );
    $msg_only ? return $msg : return $self->info_panel($msg),
  }
  return '';
}

sub content {
  ## Returns the actual content of the component
  ## @note Avoid overriding this in child class
  my $self      = shift;
  my $hub       = $self->hub;
  my $cache     = $hub->cache;
  my $cache_key = $self->cache_key;
  my $form      = $cache && $cache_key ? $cache->get($cache_key) : undef;

  # If cached form not found, generate a new form and save in cache to skip the form generation process next time
  if (!$form) {
    $form = $self->get_cacheable_form_node;
    my $error = $form->has_flag("error");
    $form = $form->render;
    $cache->set($cache_key, $form) if $cache && $cache_key && !$error;
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

  my $form_markup = '<div class="_tool_new"><p><a class="button _change_location" href="%s">%s</a></p></div><div class="hidden _tool_form_div"><input type="hidden" class="panel_type" value="%s" />%s%s%s</div>';
  if( $hub->param('expand_form') ) {
    $form_markup = '<div class="hidden _tool_new"><p><a class="button _change_location" href="%s">%s</a></p></div><div class="_tool_form_div"><input type="hidden" class="panel_type" value="%s" />%s%s%s</div>';
  }
  

  return sprintf($form_markup,
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

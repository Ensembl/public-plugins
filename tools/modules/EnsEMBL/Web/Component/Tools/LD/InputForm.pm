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

package EnsEMBL::Web::Component::Tools::LD::InputForm;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::LD
  EnsEMBL::Web::Component::Tools::InputForm
);

sub form_header_info {
  ## Abstract method implementation
  my $self = shift;

  return $self->tool_header({'reset' => 'Clear form', 'cancel' => 'Close'});
}

sub get_cacheable_form_node {
  ## Abstract method implementation
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $sd              = $hub->species_defs;
  my $species         = $object->species_list;
  my $form            = $self->new_tool_form;
  my $fd              = $object->get_form_details;
  my $input_fieldset  = $form->add_fieldset({'no_required_notes' => 1});
  my $msg             = $self->species_specific_info($self->current_species, 'LD', 'LD',1);

  my $region_input_formats   = [{ 'value' => 'region', 'caption' => 'Regions', 'example' => qq(1  809238  909238\n3  661464  861464) }];
  my $variant_input_formats = [{ 'value' => 'variant', 'caption' => 'Variants', 'example' => qq(rs17689576\nrs34954265\nrs9350462) }];

  # choose method
  $input_fieldset->add_field({
      'type'          => 'radiolist',
      'name'          => 'ld_calculation',
      'label'         => $fd->{ld_calculation}->{label},
      'helptip'       => $fd->{ld_calculation}->{helptip},
      'value'         => 'region',
      'class'         => '_stt',
      'values'        => $fd->{ld_calculation}->{values}
  });

  $input_fieldset->add_field({
    'field_class' => '_stt_region',
    'type'    => 'noedit',
    'name'    => 'img',
    'label'   => 'Selected calculation',
    'is_html' => 1,
    'caption' => '<div><img src="/i/ld_region.png" style="width:350px"></div>',
  });

  $input_fieldset->add_field({
    'field_class' => '_stt_center',
    'type'    => 'noedit',
    'name'    => 'img',
    'label'   => 'Selected calculation',
    'is_html' => 1,
    'caption' => '<div><img src="/i/ld_center.png" style="width:350px"></div>',
  });

  $input_fieldset->add_field({
    'field_class' => '_stt_pairwise',
    'type'    => 'noedit',
    'name'    => 'img',
    'label'   => 'Selected calculation',
    'is_html' => 1,
    'caption' => '<div><img src="/i/ld_pairwise.png" style="width:350px"></div>',
  });

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this job (optional)'
  });

  if (scalar @$species > 1) {
    $input_fieldset->add_field({
      'label'         => 'Species',
      'elements'      => [{
        'type'          => 'speciesdropdown',
        'name'          => 'species',
        'values'        => [ map {
          'value'         => $_->{'value'},
          'caption'       => $_->{'caption'},
          'class'         => [  #selectToToggle classes for JavaScript
            '_stt', '_sttmulti',
          ]
        }, @$species ]
      },{
      'type'          => 'noedit',
      'value'         => '<span class="_msg _stt_Homo_sapiens italic"> ('.$msg.')</span>',
      'no_input'      => 1,
      'is_html'       => 1
    } 
      ]
    });
  } else {
    my $caption = $species->[0]->{'caption'};
    $caption =~ s/\s(.*)//; # Human (Homo_sapiens) -> Human
    $input_fieldset->add_field({
      'label'         => 'Species',
      'elements'      => [{
        'selected' => 1,
        'type'     => 'noedit',
        'name'     => 'species',
        'value'    => $species->[0]->{'value'},
        'caption'  => $caption,
      }, 
      ]
    });
  }

  my $LD_populations = $object->LD_populations;
  my @select_populations;
  my @population_field_classes;
  for my $species_name (keys %$LD_populations) {
    push @select_populations, {
      'type'          => 'dropdown',
      'name'          => 'populations',
      'label'         => 'Select one or more populations',
      'values'        => $LD_populations->{$species_name},
      'size'          => '20',
      'element_class' => "_stt_$species_name tools_listbox",
      'multiple'      => '1'
    };
    push @population_field_classes, "_stt_$species_name";
  }

  $input_fieldset->add_field({
    'label'       => 'Select one or more populations',
    'elements'    => \@select_populations,
    'field_class' => \@population_field_classes,
  });


  $input_fieldset->add_field({
    'label'         => 'Either paste data',
    'elements'      => [
      {
        'type'          => 'text',
        'class'         => 'vep-input',
        'name'          => 'text',
      }, 
      {
        'element_class'   => '_stt_region',
        'type'          => 'noedit',
        'noinput'       => 1,
        'is_html'       => 1,
        'caption'       => sprintf('<span class="small"><b>Example input:&nbsp;</b>%s</span>',
          join(', ', (map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$region_input_formats))
        )
      },
      {
        'element_class'   => '_stt_pairwise _stt_center',
        'type'          => 'noedit',
        'noinput'       => 1,
        'is_html'       => 1,
        'caption'       => sprintf('<span class="small"><b>Example input:&nbsp;</b>%s</span>',
          join(', ', (map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$variant_input_formats))
        )
      }

    ]
  });

  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'VEP'} / (1024 * 1024))
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });

  $input_fieldset->add_field({
    'type'    => 'string',
    'name'    => 'r2',
    'label'   => $fd->{'r2_threshold'}->{'label'},
    'helptip' => $fd->{'r2_threshold'}->{'helptip'},
    'value'   => $fd->{'r2_threshold'}->{'value'},
  });

  $input_fieldset->add_field({
    'type'    => 'string',
    'name'    => 'd_prime',
    'label'   => $fd->{'d_prime_threshold'}->{'label'},
    'helptip' => $fd->{'d_prime_threshold'}->{'helptip'},
    'value' => $fd->{'d_prime_threshold'}->{'value'},
  });

  $input_fieldset->add_field({
    'field_class' => '_stt_center',
    'label' => $fd->{'window_size'}->{'label'},
    'helptip' => $fd->{'window_size'}->{'helptip'},
    'elements' => [{
      'name'  => 'window_size',
      'element_class' => '_stt_center',
      'type'  => 'string',
      'value' => $fd->{'window_size'}->{'value'},
    }]
  });

  # Run buttons
  $self->add_buttons_fieldset($form);

  return $form;
}

sub get_non_cacheable_fields {
  ## Abstract method implementation
  return {};
}

sub js_panel {
  ## @override
  return 'LDForm';
}

sub js_params {
  ## @override
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $species = $object->species_list;
  my $params  = $self->SUPER::js_params(@_);

  # example data for each species
  $params->{'example_data'} = { map { $_->{'value'} => delete $_->{'example'} } @$species };

  return $params;
}

1;

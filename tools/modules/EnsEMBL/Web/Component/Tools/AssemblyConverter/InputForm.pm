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

package EnsEMBL::Web::Component::Tools::AssemblyConverter::InputForm;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::AssemblyConverterConstants qw(INPUT_FORMATS);

use parent qw(EnsEMBL::Web::Component::Tools::AssemblyConverter);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $sd              = $hub->species_defs;
  my $species         = $self->_species;
  my $cache           = $hub->cache;
  my $form; #            = $cache ? $cache->get('AssemblyConverterFORM') : undef;
  my $current_species = $hub->species;
  my $input_formats   = INPUT_FORMATS;

  if (!$form) {
    $form = $self->new_tool_form('AssemblyConverter');

    # Placeholder for previous job json hidden input
    $form->append_child('text', 'EDIT_JOB');

    my $input_fieldset = $form->add_fieldset({'legend' => 'Input', 'class' => '_stt_input', 'no_required_notes' => 1});

    # Species dropdown list with stt classes to dynamically toggle other fields
    $input_fieldset->add_field({
      'label'         => 'Species',
      'type'          => 'dropdown',
      'name'          => 'species',
      'value'         => $current_species,
      'class'         => '_stt',
      'values'        => [ map {
        'value'         => $_->{'value'},
        'caption'       => $_->{'caption'},
        }, @$species ]
    }); 

    $input_fieldset->add_field({
      'label'         => 'Assembly mapping',
      'elements'      => [ map {
                            'type'          => 'dropdown',
                            'name'          => 'mappings_for_'.$_->{'value'},
                            'values'        => $_->{'mappings'},
                            'element_class' => '_stt_'.$_->{'value'},  
                          }, @$species],  
    });

    $input_fieldset->add_field({
      'type'          => 'string',
      'name'          => 'name',
      'label'         => 'Name for this data (optional)'
    });

    $input_fieldset->add_field({
      'type'          => 'dropdown',
      'name'          => 'format',
      'label'         => 'Input file format',
      'values'        => $input_formats, 
      'class'         => '_stt format'
    });

    $input_fieldset->add_field({
      'label'         => 'Either paste data',
      'elements'      => [ map {
        'type'          => 'text',
        'name'          => 'text_'.$_->{'value'},
        'element_class' => '_stt_'.$_->{'value'},
        'value'         => $_->{'example'},
        }, @$input_formats ]
    });

    $input_fieldset->add_field({
      'type'          => 'file',
      'name'          => 'file',
      'label'         => 'Or upload file',
      'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'AssemblyConverter'} / 1048576)
    });

    $input_fieldset->add_field({
      'type'          => 'url',
      'name'          => 'url',
      'label'         => 'Or provide file URL',
      'size'          => 30,
      'class'         => 'url'
    });

    # Placeholder for previous files select box
    $input_fieldset->append_child('text', 'FILES_DROPDOWN');

    $self->add_buttons_fieldset($form, {'reset' => 'Reset', 'cancel' => 'Cancel'});

    $form = $form->render;

    # Save in cache to skip the form generation process next time
    $cache->set('AssemblyConverterFORM', $form) if $cache;
  }

  # Add the non-cacheable fields to this dummy form and replace the placeholders from the actual form HTML
  my $form2 = $self->new_form;

  # Previous job params for JavaScript
  my $edit_job = ($hub->function || '') eq 'Edit' ? $self->object->get_edit_jobs_data : [];
  $edit_job = @$edit_job ? $form2->add_hidden({ 'name'  => 'edit_jobs', 'value' => $self->jsonify($edit_job) })->render : '';

# Previously uploaded files
  my $file_dropdown   = '';
  my %allowed_formats = map { $_->{'value'} => $_->{'caption'} } @$input_formats;
  my @user_files      = sort { $b->{'timestamp'} <=> $a->{'timestamp'} } grep { $_->{'format'} && $allowed_formats{$_->{'format'}} } $hub->session->get_data('type' => 'upload'), $hub->user ? $hub->user->uploads : ();

  if (scalar @user_files) {
    my @to_form = { 'value' => '', 'caption' => '-- Select file --'};

    foreach my $file (@user_files) {

      my $file_obj    = EnsEMBL::Web::TmpFile::Text->new('filename' => $file->{'filename'});
      my @file_data;
      try {
        @file_data    = file_get_contents($file_obj->full_path);
      } catch {};

      next unless @file_data;

      my $first_line  = first { $_ !~ /^\#/ } @file_data;
         $first_line  = substr($first_line, 0, 30).'&#8230;' if $first_line && length $first_line > 31;

      push @to_form, {
        'value'   => $file->{'filename'},
        'caption' => sprintf('%s | %s | %s | %s',
          $file->{'name'},
          $allowed_formats{$file->{'format'}},
          $sd->species_label($file->{'species'}, 1),
          $first_line || '-'
        )
      };
    }

    if (@to_form > 1) {
      $file_dropdown = $form2->add_field({
        'type'    => 'dropdown',
        'name'    => 'userdata',
        'label'   => 'Or select previously uploaded file',
        'values'  => \@to_form,
      })->render;
    }
  }

  # Regexp to replace all placeholders from cached form
  $form =~ s/EDIT_JOB/$edit_job/;
  $form =~ s/FILES_DROPDOWN/$file_dropdown/;

  return sprintf('
    <div class="hidden _tool_new">
      <p><a class="button _change_location" href="%s">New Assembly Converter job</a></p>
    </div>
    <div class="hidden _tool_form_div">
      <h2>New Assembly Converter job:</h2>
      <p class="info">This online tool currently uses <a href="http://crossmap.sourceforge.net">CrossMap</a>, which supports a limited number of formats (see our online documentation for <a href="/info/website/upload/index.html#formats">details of the individual data formats</a> listed below). CrossMap also discards metadata in files, so track definitions, etc, will be lost on conversion.</p>
      <p><b>Important note</b>: CrossMap converts WIG files to BedGraph internally for efficiency, and also outputs them in BedGraph format.</p>
      <input type="hidden" class="panel_type" value="AssemblyConverterForm" />%s
    </div>',
    $hub->url({'function' => ''}),
    $form
  );
}

sub _species {
  ## @private
  my $self = shift;

  if (!$self->{'_species'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;
    my %fav     = map { $_ => 1 } @{$hub->get_favourite_species};
    my @species;
    my $current_species = $hub->species;

    my $chain_files = {};
    foreach ($sd->valid_species) {
      my $files = $sd->get_config($_, 'ASSEMBLY_CONVERTER_FILES') || []; 
      $chain_files->{$_} = $files if scalar(@$files);
    }

    for (sort {$sd->get_config($a, 'SPECIES_COMMON_NAME') cmp $sd->get_config($b, 'SPECIES_COMMON_NAME')} keys %$chain_files) {
      
      my $mappings = [];
      foreach my $map (@{$chain_files->{$_}||[]}) {
        (my $caption = $map) =~ s/_to_/ -> /;
        push @$mappings, {'caption' => $caption, 'value' => $map};
      }
      my $db_config = $sd->get_config($_, 'databases');

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'mappings'    => $mappings,
        'favourite'   => $fav{$_} || 0
      };
    }

    @species = sort { ($a->{'favourite'} xor $b->{'favourite'}) ? $b->{'favourite'} || -1 : $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species'} = \@species;
  }

  return $self->{'_species'};
}

1;

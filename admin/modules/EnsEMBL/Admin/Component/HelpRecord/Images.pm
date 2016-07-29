=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::HelpRecord::Images;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use parent qw(EnsEMBL::Web::Component);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my ($error, $list);

  try {
    $list = $object->get_help_images_list;
  } catch {
    $error = $_->message;
  };

  return $self->error_panel('Error', $error) if $error;
  return $self->info_panel('Images not found', 'No images were found in the specified directory.') unless @$list;

  my $file      = $hub->param('file');
  my $function  = $hub->function;
  ($file)       = grep {$_->{'name'} eq $file} @$list if $file;

  # Upload form page
  if ($function eq 'Replace' || $function eq 'Upload') {

    if (!$file || grep {$_ eq 'Replace'} @{$file->{'action'}}) {
      my $form = $self->new_form({'action' => {'action' => 'Image', 'function' => 'Upload'}, 'enctype' => 'multipart/form-data'});
      $form->add_field({'type' => 'noedit', 'label' => 'Replace image', 'name' => 'file', 'value' => $file->{'name'}}) if $file;
      $form->add_field({'type' => 'file', 'label' => 'New image', 'name' => 'upload', 'notes' => 'Upto 500KB', 'required' => 1});
      $form->add_button({'value' => 'Upload'});
      $form->force_reload_on_submit;

      return sprintf '<h3>Upload image</h3>%s', $form->render;
    }

  # Add, Commit and then Push
  } elsif ($function eq 'Push') {

    my @to_push = grep { $_->{'status'} !~ /up-to-date/i } @$list;

    return '<p>No changes to push</p>' unless @to_push;

    my $form = $self->new_form({'action' => {'action' => 'Image', 'function' => 'Push'}});
    $form->add_field({'type' => 'checklist', 'name' => 'files', 'label' => 'Files to be pushed', 'values' => [ map {
      'value'   => $_->{'name'},
      'group'   => $_->{'status'},
      'caption' => $_->{'name'},
      'checked' => 1
    }, @to_push ]});
    $form->add_field({'type' => 'string', 'label' => 'Message', 'name' => 'message', 'value' => 'Committed via Admin Site'});
    $form->add_button({'value' => 'Push to GitHub'});
    $form->force_reload_on_submit;

    return sprintf '<h3>Push changes</h3>%s', $form->render;

  } elsif ($file && grep {$_ eq $function} @{$file->{'action'}}) { # perform these action only if allowed

    # Delete confirmation page
    if ($function eq 'Delete') {

      return $self->info_panel("Delete $file->{'name'}",
        sprintf('<p>Are you sure you want to delete this image?</p><p class="button"><a href="%s">Yes</a><a href="%s">No</a></p>',
          $hub->url({'action' => 'Image', 'function' => 'Delete', 'file' => $file->{'name'}}),
          $hub->url({'function' => 'List'})
        ),
        '100%'
      );

    # Reset local changes to the file
    } elsif ($function eq 'Reset') {

      return $self->info_panel("Reset $file->{'name'}",
        sprintf('<p>Are you sure you want to reset all the changes made to this image?</p><p class="button"><a href="%s">Yes</a><a href="%s">No</a></p>',
          $hub->url({'action' => 'Image', 'function' => 'Reset', 'file' => $file->{'name'}}),
          $hub->url({'function' => 'List'})
        ),
        '100%'
      );

    # View image page
    } elsif ($function eq 'View') {

      my $buttons = [ {
        'node_name'   => 'a',
        'class'       => 'modal_link',
        'href'        => $hub->url({'function' => 'List'}),
        'inner_HTML'  => 'View all'
      }, map {$_ eq 'View' ? () : {
        'node_name'   => 'a',
        'class'       => 'modal_link',
        'href'        => $hub->url({'function' => $_, 'file' => $file->{'name'}}),
        'inner_HTML'  => $_
      }} @{$file->{'action'}} ];

      my $info        = $object->get_image_details($file->{'modified'} || $file->{'name'});
      my $dir         = $object->get_help_images_dir;
      my $embed_code  = $info->{'dim'} ? qq([[IMAGE::$file->{'name'} height="$info->{'dim'}{'y'}" width="$info->{'dim'}{'x'}"]]) : '';

      my $image_divs  = [{
        'node_name'     => 'div',
        'class'         => 'tinted-box',
        'children'      => [ $file->{'modified'} ? {
          'node_name'     => 'p',
          'inner_HTML'    => 'Modified Version'
        } : (), $file->{'status'} =~ /deleted/i ? {
          'node_name'     => 'p',
          'inner_HTML'    => '<b>Deleted</b>'
        } : {
          'node_name'     => 'p',
          'children'      => [{
            'node_name'     => 'img',
            'src'           => sprintf('%4$s/%s?cache=%s', $file->{'modified'} || $file->{'name'}, $info->{'md5'}, split('/htdocs', $dir)),
            'alt'           => $file->{'name'}
          }]
        }]
      }];

      if ($file->{'modified'} && (my $info_previous = $object->get_image_details($file->{'name'}))) { # if we have a modified version
        push @$image_divs, {
          'node_name'   => 'div',
          'class'       => 'tinted-box',
          'children'    => [{
            'node_name'   => 'p',
            'inner_HTML'  => 'Previous version'
          }, {
            'node_name'   => 'p',
            'children'    => [{
              'node_name'   => 'img',
              'src'         => sprintf('%4$s/%s?cache=%s', $file->{'name'}, $info_previous->{'md5'}, split('/htdocs', $dir)),
              'alt'         => "Previous version of $file->{'name'}"
            }]
          }]
        };
      }

      return $self->dom->create_element('div', { 'children' => [
        {'node_name' => 'h3', 'inner_HTML' => "View $file->{'name'}" },
        @$image_divs,
        $embed_code ? {'node_name' => 'p', 'inner_HTML' => qq(Embed code: <span class="code">$embed_code</span>)} : (),
        @$buttons   ? {'node_name' => 'p', 'class' => 'button', 'children' => $buttons} : ()
      ] })->render;
    }
  }

  # List page - display default table for 'List', no or wrong function part of the url
  my $table   = $self->new_table([
    {'key'  => 'name',    'title' => 'Name', 'sort' => 'html'},
    {'key'  => 'size',    'title' => 'Size', 'sort' => 'numeric_hidden'},
    {'key'  => 'status',  'title' => 'GIT status'},
    {'key'  => 'action',  'title' => 'Action', 'sort' => 'none'}
  ], [], {'data_table' => 1, 'class' => 'no_col_toggle', 'exportable' => 0});

  for my $file (@$list) {
    $file->{'size'}   = sprintf('<span class="hidden">%s</span>', $file->{'size'} || 0).($file->{'size'} ? $file->{'size'} >= 1024 ? sprintf('%d KB', ($file->{'size'} + 512) / 1024) : '< 1 KB' : 'Unknown');
    $file->{'action'} = $file->{'action'}
      ? join ' &middot; ', map { sprintf '<a href="%s">%s</a>', $hub->url({'action' => 'Images', 'function' => $_, 'file' => $file->{'name'}}), $_ } @{$file->{'action'}}
      : '<i>Permission denied to make any changes</i>'
    ;

    $table->add_row($file);
  }

  return sprintf '<p class="button"><a href="%s" class="modal_link">Add new image</a><a href="%s">Push changes to GitHub</a></p>%s',
    $hub->url({'action' => 'Images', 'function' => 'Upload'}),
    $hub->url({'action' => 'Images', 'function' => 'Push'}),
    $table->render;
}

1;

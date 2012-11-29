package EnsEMBL::Admin::Component::HelpRecord::Images;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Web::Component);

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
  if ($function eq 'Upload') {

    if (!$file || grep {$_ eq 'Upload'} @{$file->{'action'}}) {
      my $form = $self->new_form({'action' => {'action' => 'Image', 'function' => 'Upload'}});
      $form->add_field({'type' => 'noedit', 'label' => 'Replace image', 'name' => 'file', 'value' => $file->{'name'}}) if $file;
      $form->add_field({'type' => 'file', 'label' => 'New image', 'name' => 'upload', 'notes' => 'Upto 500KB', 'required' => 1});
      $form->add_button({'value' => 'Upload'});
      $form->force_reload_on_submit;

#      return sprintf '<h3>Upload image</h3>%s', $form->render;
      my $html = sprintf '<h3>Upload image</h3>%s', $form->render;
      $html =~ s/\s+target="uploadframe"\s+/ /; # TODO remove this hack once these pages work on modal window
      return $html;
    }

  } elsif ($file && grep {$_ eq $function} @{$file->{'action'}}) { # perform these action only if allowed

    # Delete confirmation page
    if ($function eq 'Delete') {

      return $self->info_panel(
        sprintf('%s %s', $file->{'cvs'} eq 'New' ? 'Delete' : 'Reset', $file->{'name'}),
        sprintf('<p>Are you sure you want to %s?</p><p class="button"><a href="%s">Yes</a><a href="%s">No</a></p>',
          $file->{'cvs'} eq 'New' ? 'delete this file' : 'ignore any local modifications and update this file from head',
          $hub->url({'action' => 'Image', 'function' => 'Delete', 'file' => $file->{'name'}}),
          $hub->url({'function' => ''})
        ),
        '100%'
      );

    # Commit form page
    } elsif ($function eq 'Commit') {

      my $form = $self->new_form({'action' => {'action' => 'Image', 'function' => 'Commit'}});
      $form->add_field({'type' => 'noedit', 'label' => 'File to Commit', 'name' => 'file', 'value' => $file->{'name'}});
      $form->add_field({'type' => 'string', 'label' => 'Message', 'name' => 'message', 'shortnote' => sprintf(' - Committed by %s via Admin site', split('@', $hub->user->email)), 'no_asterisk' => 1, 'required' => 1});
      $form->add_button({'value' => 'Commit'});
      $form->force_reload_on_submit;

      return sprintf '<h3>CVS commit</h3>%s', $form->render;

    # View image page
    } elsif ($function eq 'View') {

      my $buttons = [ map {$_ eq 'View' ? () : {
        'node_name'   => 'a',
        'class'       => 'modal_link',
        'href'        => $hub->url({'function' => $_, 'file' => $file->{'name'}}),
        'inner_HTML'  => _get_link_caption($file, $_)
      }} @{$file->{'action'}} ];

      my $embed_code = $file->{'dim'} ? qq([[image=$file->{'name'} height="$file->{'dim'}{'y'}" width="$file->{'dim'}{'x'}"]]) : '';

      return $self->dom->create_element('div', {
        'children' => [
          {'node_name' => 'h3', 'inner_HTML' => "View $file->{'name'}"},
          {'node_name' => 'div', 'class' => 'tinted-box', 'children' => [
            {'node_name' => 'p', 'children' => [
              {'node_name' => 'img', 'src' => sprintf('%4$s%s?cache=%s', $file->{'name'}, $file->{'md5'}, split('/htdocs', $object->get_help_images_dir)), 'alt' => $file->{'name'}}
            ]}
          ]},
          $embed_code ? {'node_name' => 'p', 'inner_HTML' => qq(Embed code: <span class="code">$embed_code</span>)} : (),
          @$buttons   ? {'node_name' => 'p', 'class' => 'button', 'children' => $buttons} : ()
        ]
      })->render;
    }
  }

  # List page - display default table for 'List', no or wrong function part of the url
  my $table   = $self->new_table([
    {'key'  => 'name',    'title' => 'Name', 'sort' => 'html'},
    {'key'  => 'size',    'title' => 'Size', 'sort' => 'numeric'},
    {'key'  => 'cvs',     'title' => 'CVS status'},
    {'key'  => 'action',  'title' => 'Action', 'sort' => 'none'}
  ], [], {'data_table' => 1, 'class' => 'no_col_toggle', 'exportable' => 0});

  for my $file (@$list) {
    $file->{'cvs'}   .= " (Tag: $file->{'tag'})" if $file->{'tag'};
    $file->{'size'}   = $file->{'size'} ? sprintf '%d KB', $file->{'size'} / 1024 : 'Unknown';
    $file->{'action'} = $file->{'action'}
      ? join ' &middot; ', map
        {
          sprintf '<a href="%s">%s</a>',
          $hub->url({'action' => 'Image'.($_ eq 'Update' ? '' : 's'), 'function' => $_, 'file' => $file->{'name'}}),
          _get_link_caption($file, $_)
        }
        @{$file->{'action'}}
      : '<i>Permission denied to make any changes</i>'
    ;

    $table->add_row($file);
  }

  return sprintf '%s<p class="button"><a href="%s" class="modal_link">%s</a></p>', $table->render, $hub->url({'action' => 'Images', 'function' => 'Upload'}), 'Add new image';
}

sub _get_link_caption {
  my ($file, $action) = @_;
  return 'Upload new'                                   if $action eq 'Upload';
  return 'Update from head'                             if $action eq 'Update' && $file->{'tag'};
  return $file->{'cvs'} eq 'New' ? 'Delete' : 'Reset'   if $action eq 'Delete';
  return $action;
}

1;
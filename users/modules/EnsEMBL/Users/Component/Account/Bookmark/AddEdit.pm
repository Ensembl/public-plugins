package EnsEMBL::Users::Component::Account::Bookmark::AddEdit;

### Component to edit bookmark
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $is_add_new  = $hub->function eq 'Add';

  if (my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $is_add_new ? 0 : ($hub->param('id'), $hub->param('group')) )) {

    my $form = $self->new_form({'action' => $hub->url({qw(action Bookmark function Save)})});

    $form->add_hidden({'name' => 'id',       'value'  => $bookmark->record_id });
    $form->add_hidden({'name' => 'group',    'value'  => $owner->group_id     }) if $owner->RECORD_TYPE eq 'group';
    $form->add_hidden({'name' => 'object',   'value'  => $_}) for $hub->referer->{'ENSEMBL_TYPE'};
    $form->add_field({'type'  => 'string',   'name'   => 'name',        'label' => 'Bookmark name',     'value' => $bookmark->name        || $hub->param('name')      || '',  'required' => 1 });
    $form->add_field({'type'  => 'string',   'name'   => 'shortname',   'label' => 'Short description', 'value' => $bookmark->shortname   || $hub->param('shortname') || ''});
    $form->add_field({'type'  => 'text',     'name'   => 'url',         'label' => 'Bookmark URL',      'value' => $bookmark->url         || $hub->param('url')       || '',  'required' => 1 });
    $form->add_field({'type'  => 'submit',   'value'  => $is_add_new ? 'Add' : 'Save'});

    return $form->render;

  } else {

    my $bookmarks = $hub->user->bookmarks;

    # display form to select a bookmark if no group was specified
    if (@$bookmarks) {
      return $self->js_section({
        'subsections' => [ $self->select_bookmark_form({
          'bookmarks'   => $bookmarks,
          'action'      => $hub->url({'action' => 'Bookmark', 'function' => 'Edit'}),
          'label'       => 'Select a bookmark to edit',
          'submit'      => 'Edit'
        })->render ]
      });
    
    # if no bookmark added yet
    } else {

      return $self->no_bookmark_found_page;
    }
  }
}

1;

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
    $form->add_hidden({'name' => 'group',    'value'  => $owner->group_id     }) if $owner->RECORD_OWNER_TYPE eq 'group';
    $form->add_field({'type'  => 'string',   'name'   => 'name',        'label' => 'Name',        'value' => $bookmark->name        || $hub->param('name')  || '',  'required' => 1 });
    $form->add_field({'type'  => 'text',     'name'   => 'url',         'label' => 'Location',    'value' => $bookmark->url         || $hub->param('url')   || '',  'required' => 1 });
    $form->add_field({'type'  => 'text',     'name'   => 'description', 'label' => 'Description', 'value' => $bookmark->description || '' });
    $form->add_field({'type'  => 'submit',   'value'  => $is_add_new ? 'Add' : 'Save'});

    return $form->render;

  } else {

    if (my @bookmarks = @{$hub->user->bookmarks}) {
      # display form to select a bookmark if no group was specified
      return $self->js_section({
        'subsections' => [ $self->select_bookmark_form({
          'bookmarks'   => \@bookmarks,
          'action'      => $hub->url({'action' => 'Bookmark', 'function' => 'Edit'}),
          'label'       => 'Select a bookmark to edit',
          'submit'      => 'Edit'
        })->render ]
      });
    } else {
      return $self->render_message('MESSAGE_BOOKMARK_NOT_FOUND', {'error' => 1});
    }
  }
}

1;

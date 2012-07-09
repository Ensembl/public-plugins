package EnsEMBL::Users::Component::Account::Bookmarks::AddEdit;

### Component to edit bookmark
### @author hr5

use strict;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $is_add_new  = $hub->function eq 'Add';
  my $record_type = $hub->param('group') && !$is_add_new ? 'group' : 'user'; # new bookmark can only be added to user records, not group records

  my $owner       = $user;
  if ($record_type eq 'group') {
    my $membership = $object->fetch_accessible_membership_for_user($owner, $hub->param('group'), {'query' => ['group.status' => 'active']});
    $owner = $membership ? $membership->group : undef;
  }

  if (my $bookmark = $owner
    ? !$is_add_new
    ? $hub->param('id')
    ? shift @{$owner->find_bookmarks('query' => [ "${record_type}_record_id" => $hub->param('id') ])}
    : undef
    : $user->create_record('bookmark') # owner here should always be the user 
    : undef
  ) {

    my $form = $self->new_form({'action' => $hub->url({qw(action Bookmarks function Save)})});

    $form->add_hidden({'name' => 'id',       'value'  => $bookmark->$_}) for "${record_type}_record_id";
    $form->add_field({'type'  => 'string',   'name'   => 'name',    'label' => 'Name',        'value' => $bookmark->name        || $hub->param('shortname') || $hub->param('name') || '',  'required' => 1 });
    $form->add_field({'type'  => 'text',     'name'   => 'url',     'label' => 'Location',    'value' => $bookmark->url         || $hub->param('url')       || '',                         'required' => 1 });
    $form->add_field({'type'  => 'text',     'name'   => 'url',     'label' => 'Description', 'value' => $bookmark->description || '' });
    $form->add_field({'type'  => 'submit',   'value'  => $is_add_new ? 'Add' : 'Save'});

    return $form->render;

  } else {

    # display form to select a bookmark if no group was specified
    return $self->js_section({
      'subsections' => [ $self->select_bookmark_form({
        'bookmarks'   => $user->bookmarks,
        'action'      => $hub->url({'action' => 'Bookmarks', 'function' => 'Edit'}),
        'label'       => 'Select a bookmark to edit',
        'submit'      => 'Edit'
      })->render ]
    });
  }
}

1;
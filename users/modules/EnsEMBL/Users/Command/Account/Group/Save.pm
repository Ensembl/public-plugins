package EnsEMBL::Users::Command::Account::Group::Save;

### Command module to save group details edited by the logged in admin
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $group_id    = $hub->param('id');

  # if no id given, it's a request to create a new group
  my $membership  = $group_id
    ? $object->fetch_accessible_membership_for_user($user->rose_object, $group_id)
    : $user->rose_object->create_new_membership_with_group
    or return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => '', 'err' => MESSAGE_GROUP_NOT_FOUND}));

  my $group       = $membership->group;
  my $new_values  = { map {$_ => $hub->param($_)} $hub->param }; # get all the new values from CGI

  # changes only admin can make
  if ($membership->level eq 'administrator') {

    # original values
    my $group_columns   = $group_id && $group->status eq 'inactive' ? [ qw(status) ] : [ qw(name type blurb status) ]; # for an inactive group, only status can be changed
    my $original_values = $group_id ? { map { $_ => $group->$_ } @$group_columns } : {};

    # default values if creating a new group
    unless ($group_id) {
      $new_values->{'name'}   ||= sprintf q(%s's group), $user->name;
      $new_values->{'blurb'}  ||= sprintf q(%s's group), $user->name;
      $new_values->{'type'}   ||= 'restricted';
      $new_values->{'status'}   = 'active';
    }

    # validation
    $new_values->{'type'}   = $new_values->{'type'}   && $new_values->{'type'}    =~ /^(open|private)$/ ? $new_values->{'type'} : 'restricted'  if exists $new_values->{'type'};
    $new_values->{'status'} = $new_values->{'status'} && $new_values->{'status'}  eq 'inactive'         ? 'inactive'            : 'active'      if exists $new_values->{'status'};

    # only change the column values if new values exist (ie if a GET param is set for that column name)
    exists $new_values->{$_} and $group->$_($new_values->{$_}) for @$group_columns;
    $group->save('user' => $user);

    # do we need to notify anyone about the changes?
    $self->send_group_editing_notification_email($user, $group, $original_values, { map { $_ => $group->$_ } @$group_columns }) if $group_id;

    # Changes to membership object
    exists $new_values->{$_} and $membership->$_($new_values->{$_}) for qw(notify_join notify_edit notify_share);

  # changes any member can make
  } else {
    $membership->notify_share($new_values->{'notify_share'}) if exists $new_values->{'notify_share'};
  }

  $membership->group_id($group->group_id);
  $membership->save('user' => $user);

  return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id}));
}

1;

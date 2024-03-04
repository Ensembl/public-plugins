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

package EnsEMBL::Users::Component::Account::Groups::AddEdit;

### Component to edit group name/details etc
### This page does not check whether the user has any group membership or not, so that check is applied in Configuration::Account
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_INACTIVE);

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user->rose_object;
  my $is_add_new  = $hub->function eq 'Add';
  my $membership  = $is_add_new ? $user->create_new_membership_with_group : $object->fetch_accessible_membership_for_user($user, $hub->param('id'));

  if ($membership) {

    my $group       = $membership->group;

    # dont allow editing an inactive group
    return $self->render_message(MESSAGE_GROUP_INACTIVE, {'error' => 1}) if !$is_add_new && $group->status eq 'inactive';

    my $level       = $membership->level;
    my $notif_types = $self->get_notification_types;
    my $form        = $self->new_form({'action' => {qw(action Group function Save)}, 'csrf_safe' => 1});

    $form->add_hidden({'name' => 'id', 'value'  => $group->group_id});
    $form->add_hidden({'name' => $self->_JS_CANCEL, 'value' => $is_add_new ? $hub->PREFERENCES_PAGE : $hub->url({'action' => 'Groups', 'function' => 'View', 'id' => $group->group_id})});

    if ($level eq 'administrator') {
      my $group_types       = $self->get_group_types;
      my $group_type_values = [];
      while (my ($v, $c) = splice @$group_types, 0, 2) {
        push @$group_type_values, {'value' => $v, 'caption' => {'inner_HTML' => sprintf '%s: %s', uc $v, $self->helptip($c)}};
      }
      $form->add_field({'type'  => 'string',    'name'  => 'name',    'label' => 'Group name',    'value' => $group->name,    'required' => 1                 });
      $form->add_field({'type'  => 'text',      'name'  => 'blurb',   'label' => 'Description',   'value' => $group->blurb                                    });
      $form->add_field({'type'  => 'radiolist', 'name'  => 'type',    'label' => 'Group type',    'value' => $group->type,    'values' => $group_type_values  });
    }
    $form->add_field({'type'    => 'yesno', 'value' => $membership->$_ || 0, 'name' => $_, 'label' => $notif_types->{$_}, 'is_binary' => 1}) for $level eq 'administrator' ? qw(notify_join notify_edit notify_share) : qw(notify_share);
    $form->add_field({'inline'  => 1, 'elements' => [
      {'type' => 'submit', 'value' => $is_add_new ? 'Add' : 'Save'},
      {'type' => 'reset',  'value' => 'Cancel', 'class' => $self->_JS_CANCEL}
    ]});

    return $self->js_section({'subsections' => [ $form->render ]});

  } else {

    my $memberships = $user->active_memberships;

    # display form to select a group if no group was specified
    return $self->js_section({
      'heading'     => 'Edit group',
      'subsections' => [ @$memberships ? $self->select_group_form({
        'memberships' => $memberships,
        'action'      => {'action' => 'Groups', 'function' => 'Edit'},
        'label'       => 'Select a group to edit',
        'submit'      => 'Edit'
      })->render : $self->no_group_message ]
    });
  }
}

1;

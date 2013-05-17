package EnsEMBL::Users::Command::Account::Membership;

### Allows the user to accept or decline a membership invitation, or allows the admin user to allow or ignore a membership request from a user

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND);

use base qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $membership  = $hub->function ne 'Create'
    ? $hub->param('id')
    ? $object->fetch_membership($hub->param('id'), {'with_objects' => 'group', 'query' => ['group.status' => 'active']})
    : undef
    : $user->rose_object->create_membership_object
  or return $self->redirect_message(MESSAGE_GROUP_NOT_FOUND, {'error' => 1, 'back' => $self->redirect_url});

  $membership->save('user' => $user) if $self->modify_membership($membership);

  return $self->ajax_redirect($self->redirect_url);
}

sub redirect_url {
  my $self  = shift;
  my $hub   = $self->hub;
  $self->{'_redirect_url'} = shift if @_;
  return $self->{'_redirect_url'} ? $hub->url($self->{'_redirect_url'}) : $hub->PREFERENCES_PAGE;
}

sub modify_membership {} # implemented in child classes

1;
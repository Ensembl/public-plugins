package EnsEMBL::Users::Command::Account::Membership;

### Allows the user to accept or decline a membership invitation, or allows the admin user to allow or ignore a membership request from a user

use strict;
use warnings;

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $membership  = $hub->param('id') ? $object->fetch_membership($hub->param('id')) : undef or return $self->redirect_message($object->get_message_code('MESSAGE_GROUP_NOT_FOUND'), {'error' => 1});

  $membership->save('user' => $user) if $self->modify_membership($membership);

  return $self->ajax_redirect($self->redirect_url);
}

sub redirect_url {
  my $self  = shift;
  my $hub   = $self->hub;
  $self->{'_redirect_url'} = shift if @_;
  return $self->{'_redirect_url'} ? $hub->url($self->{'_redirect_url'}) : $self->internal_referer;
}

sub modify_membership {} # implemented in child classes

1;
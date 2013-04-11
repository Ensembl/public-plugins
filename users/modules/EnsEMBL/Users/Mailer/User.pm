package EnsEMBL::Users::Mailer::User;

use strict;
use warnings;

## TODO - why do we need logged-in user in some arguments? use hub->user instead

use base qw(EnsEMBL::Web::Mailer);

sub set_noreply_sender {
  ## Sets the 'from' field as ENSEMBL_NOREPLY_EMAIL
  ## Call this for sending emails to unregistered emails (likely to be invalid) so that the ENSEMBL_HELPDESK_EMAIL doesn't get bombarded with bounced email.
  my $self    = shift;
  $self->from = $self->hub->species_defs->ENSEMBL_NOREPLY_EMAIL;
}

sub send_verification_email {
  ## Sends an activation email to newly registered users
  ## @param Login object that needs to be verified
  my ($self, $login) = @_;

  my $sitename  = $self->site_name;
  my $user      = $login->user;
  my $provider  = $login->provider || '';
  my $identity  = $login->has_trusted_provider ? $login->email : $login->identity;
  my $type      = $login->type;
  my $function  = $type eq 'openid' ? 'Verify' : 'Confirm';
  my $email     = $user->email;
  my $url       = $self->url({
    'species'     => '',
    'type'        => 'Account',
    'action'      => 'Details',
    'function'    => $function,
    'code'        => $login->get_url_code
  });

  my $message   = {
    'openid'      =>  qq{If you recently tried to login to $sitename using your OpenID account with $provider ($identity), to verify your }
                     .qq(email address '$email', please go to the following url:\n\n\n$url\n\n\n"."This will allow )
                     .qq(you access to $sitename using your account with $provider.),
    'local'       =>  qq(If you recently registered with $sitename, to confirm your email address as '$email', please go to the )
                     .qq(following url:\n\n\n$url\n\n\nThis will allow you access to $sitename using the provided )
                     .qq(email address and password you will choose later.),
  };

  $self->to      = $email;
  $self->subject = qq($sitename: $function your email address);
  $self->message = $message->{$type}.$self->email_footer;
  $self->set_noreply_sender;
  $self->send;
}

sub send_password_retrieval_email {
  ## Send email to the registered email with a link to retrieve password for a 'local' login
  ## @param Login object whose password needs to be retrieved
  my ($self, $login) = @_;

  my $sitename    = $self->site_name;
  my $email       = $login->email;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'species'       => '',
    'type'          => 'Account',
    'action'        => 'Password',
    'function'      => 'Change',
    'code'          => $login->get_url_code
  });

  $self->to       = $email;
  $self->subject  = qq($sitename: Instructions to retrieve your password);
  $self->message  = qq(If you recently requested to retrieve your password to login to $sitename using your email address '$email', please go )
                   .qq(to the following url:\n\n\n$url\n\n\nThis will allow you to reset your password and be able to login to the site again.\n\n)
                   .qq(Please ignore this email if you have not requested to retrieve you password.$footer);

  $self->set_noreply_sender;
  $self->send;
}

sub send_change_email_confirmation_email {
  ## Sends an email to the new email address if the user want to change his email
  ## @param Any active login object related to the user
  ## @param New email string
  my ($self, $login, $new_email) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $old_email   = $login->user->email;
  my $login_text  = $login->type eq 'local' ? ' and be able to login to the site with the new email' : '';
  my $url         = $self->url({
    'species'       => '',
    'type'          => 'Account',
    'action'        => 'Details',
    'function'      => 'ChangeEmail',
    'code'          => $login->get_url_code,
    'email'         => $new_email
  });

  $self->to       = $new_email;
  $self->subject  = qq($sitename: Confirm your email address);
  $self->message  = qq(If you requested to change your email address from $old_email to $new_email on your account with $sitename, to confirm your request, )
                   .qq(please go to the following url:\n\n\n$url\n\n\nThis will allow you to change your email address on our records$login_text.\n\n)
                   .qq(Please ignore this email if you have not put any such request.$footer);

  $self->send;
}

sub send_group_sharing_notification_email {
  ## Sends emails to the given members about records shared with a group
  ## @param Members to send emails to (ArrayRef)
  ## @param Group object
  ## @param Items shared (string)
  my ($self, $members, $group, $shared_items) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'type'          => 'Account',
    'action'        => 'Groups',
    'function'      => 'View',
    'id'            => $group->group_id
  });
  my $user        = $self->hub->user;
  my $by_name     = $user->name;
  my $by_email    = $user->email;
  my $group_name  = $group->name;
  my $message     = qq{Dear %s,\n\nThis email is to notify you that $by_name has shared the following items with the group "$group_name"}
                   .qq(\n\n$shared_items\n\nYou have received this email since you have opted to get notified when someone shares something with this group. To view the shared items, )
                   .qq(or to change your email preferences, please go to the link below:\n\n$url\n$footer);

  $self->subject  = qq($sitename: Items shared to group "$group_name");

  for (@$members) {
    $self->message  = sprintf $message, $_->name;
    $self->to       = $_->email;
    $self->send;
  }
}

sub send_group_editing_notification_email {
  ## Sends emails to the given admins of the group about the changes done to a group
  ## @param Admins to send emails to (ArrayRef)
  ## @param Group that's been changed
  ## @param Changes made (string)
  my ($self, $admins, $group, $changes) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'type'          => 'Account',
    'action'        => 'Groups',
    'function'      => 'View',
    'id'            => $group->group_id
  });
  my $user        = $self->hub->user;
  my $by_name     = $user->name;
  my $by_email    = $user->email;
  my $group_name  = $group->name;
  my $message     = qq{Dear %s,\n\nThis email is to notify you that the following changes have been made to the group "$group_name" by administrator $by_name ($by_email):}
                   .qq(\n\n$changes\n\nYou have received this email since you have opted to get notified when someone makes any change to this group. To view the changes made, )
                   .qq(or to change your email preferences, please go to the link below:\n\n$url\n$footer);

  $self->subject  = qq($sitename: Changes made to group "$group_name");

  for (@$admins) {
    $self->message  = sprintf $message, $_->name;
    $self->to       = $_->email;
    $self->send;
  }
}

sub send_group_deletion_notification_email {
  ## Sends emails to the given admins notifying them about the deletion of the group
  ## @param Admins to send email to (Arrayref)
  ## @param Name of the deleted group
  my ($self, $admins, $group_name) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'type'          => 'Account',
    'action'        => 'Groups',
    'function'      => ''
  });
  my $user        = $self->hub->user;
  my $by_name     = $user->name;
  my $by_email    = $user->email;
  my $message     = qq{Dear %s,\n\nThis email is to notify you that the group "$group_name" have been deleted by administrator $by_name ($by_email).\n\n}
                   .qq(You have received this email since you have opted to get notified when someone makes any change to this group. To view your other groups, )
                   .qq(or to change your email preferences for other groups, please go to the link below:\n\n$url\n$footer);

  $self->subject  = qq($sitename: Group "$group_name" deleted);

  for (@$admins) {
    $self->message  = sprintf $message, $_->name;
    $self->to       = $_->email;
    $self->send;
  }
}

sub send_group_joining_notification_email {
  ## Send emails to the given admins notifying them about a new joinee
  ## @param Admins of the group (ArrayRef)
  ## @param Group object
  ## @param Flag to tell whether user joined or requested for membership
  my ($self, $admins, $group, $has_joined) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'type'          => 'Account',
    'action'        => 'Groups',
    'function'      => 'View',
    'id'            => $group->group_id
  });
  my $user        = $self->hub->user;
  my $by_name     = $user->name;
  my $by_email    = $user->email;
  my $group_name  = $group->name;
  my $action      = $has_joined ? 'has joined' : 'has sent request to join';
  my $action_2    = $has_joined ? '' : 'or to accept or decline the request, ';
  my $message     = qq{Dear %s,\n\nThis email is to notify you that $by_name ($by_email) $action the group "$group_name".\n\n}
                   .qq(You have received this email since you have opted to get notified when someone joins this group. To view the group, $action_2)
                   .qq(or to change your email preferences, please go to the link below:\n\n$url\n$footer);

  $self->subject  = qq($sitename: "$by_name" $action the group "$group_name");

  for (@$admins) {
    $self->message  = sprintf $message, $_->name;
    $self->to       = $_->email;
    $self->send;
  }
}

sub send_group_invitation_email_to_existing_user {
  ## Sends an invitation email to the given user for the given group
  ## @param Group object
  ## @param User to be invited
  my ($self, $group, $invitee) = @_;

  my $sitename    = $self->site_name;
  my $footer      = $self->email_footer;
  my $url         = $self->url({
    'species'       => '',
    'type'          => 'Account',
    'action'        => 'Preferences'
  });
  my $to_name     = $invitee->name;
  my $user        = $self->hub->user;
  my $by_name     = $user->name;
  my $group_name  = $group->name;

  $self->to       = $invitee->email;
  $self->reply    = $user->email;
  $self->subject  = qq($sitename: Invitation from $by_name to join group "$group_name");
  $self->message  = qq(Dear $to_name,\n\n$by_name would like you to join the group "$group_name". To accept or decline the invitation, )
                   .qq(or to block the group from sending you further invitations, please go to the link below:\n\n$url\n$footer);
  $self->set_noreply_sender;

  $self->send;
}

sub send_group_invitation_email_to_new_user {
  ## Sends an invitation email to the given user for the given group
  ## @param Group object
  ## @param Email of the new user to be invited
  ## @param Invitation object
  my ($self, $group, $email, $invitation) = @_;

  my $sitename        = $self->site_name;
  my $footer          = $self->email_footer;
  my $invitation_url  = {
    'species'           => '',
    'type'              => 'Account',
    'action'            => 'Membership',
    'function'          => 'Create',
    'invitation'        => $invitation->get_invitation_code,
    'csrf_safe'         => 1,
    'user'              => undef
  };
  my $url_1           = $self->url($invitation_url);
  my $url_2           = $self->url({
    'species'           => '',
    'type'              => 'Account',
    'action'            => 'Register',
    'then'              => $self->hub->url($invitation_url)
  });
  my $user            = $self->hub->user;
  my $by_name         = $user->name;
  my $group_name      = $group->name;

  $self->to           = $email;
  $self->reply        = $user->email;
  $self->subject      = qq($sitename: Invitation from $by_name to join group "$group_name" on $sitename);
  $self->message      = qq(Hi,\n\n$by_name would like you to join the group "$group_name" on $sitename. To register with $sitename and join the group, )
                       .qq(please click on the link below:\n\n$url_2\n\nIf you already have an account with $sitename, to accept or decline the invitation, )
                       .qq(or to block the group from sending you further invitations, please go the link below:\n\n$url_1\n\n$footer)
                       .qq(If you do not have an account with $sitename and would like to accept the invitation, please click on the link below to register);
  $self->set_noreply_sender;

  $self->send;
}

sub send_mailinglists_subscription_emails {
  ## Sends emails to the address provided to join the selected mailing lists
  ## @param Login object
  ## @params Email addressed to which emails are to be sent to subscribe the user to the email list
  my ($self, $login, @subscription_emails) = @_;

  $self->subject  = "Subscription";
  $self->message  = "Subscription";
  $self->from     = $login->user->email;

  for (@subscription_emails) {
    $self->to = $_;
    $self->send;
  }
}

1;

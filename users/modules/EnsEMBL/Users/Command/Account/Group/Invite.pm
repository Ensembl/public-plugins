package EnsEMBL::Users::Command::Account::Group::Invite;

### Command module to send invitation emails for a group to one or more users
### @author hr5

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND MESSAGE_EMAILS_INVALID MESSAGE_GROUP_INVITATION_SENT);

use base qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $admin       = $hub->user;
  my $group_id    = $hub->param('group_id');

  my $membership  = $group_id ? $object->fetch_active_membership_for_user($admin->rose_object, $group_id, {'query' => ['level' => 'administrator']}) : undef
    or return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'Invite', 'err' => MESSAGE_GROUP_NOT_FOUND}));

  my $group       = $membership->group;

  # validate the emails, separate the invalid ones
  my $invalid_emails  = [];
  my $valid_emails    = [ grep {$_ ne $admin->email} map { $self->validate_fields({'email' => $_ || ''})->{'email'} || push(@$invalid_emails, $_) && () } sort keys %{{ map {$_ =~ s/^\s*|\s*$//g; $_ ? ($_ => 1) : ()} split ',', $hub->param('emails') || '' }} ];

  if (@$invalid_emails) {
    return $self->ajax_redirect($hub->url({
      'action'    => 'Groups',
      'function'  => 'Invite',
      'err'       => MESSAGE_EMAILS_INVALID,
      'emails'    => join(', ', @$valid_emails),
      'invalids'  => join(', ', @$invalid_emails),
      'id'        => $group_id
    }));

  } else {

    my $mailer = $self->get_mailer;
    foreach my $email (@$valid_emails) {

      # for an existing ensembl user
      if (my $invitee = $object->fetch_user_by_email($email)) {

        my $membership = $group->membership($invitee);

        # ignore these cases
        next if $membership->is_group_blocked || $membership->is_active;

        if ($membership->is_pending_request) { # just activate the membership and skip sending email
          $membership->activate;
          $membership->save(user => $admin)
        } else {
          $membership->make_invitation;
          $mailer->send_group_invitation_email_to_existing_user($group, $invitee, $admin) if $membership->save(user => $admin);
        }

      # for a new user (unregistered email)
      } else {

        ## create a group record invitation
        my ($invitation) = grep {$_->email eq $email} @{$group->find_invitations};
        if ($invitation) {
          $invitation->save(user => $admin);
        } else {
          $invitation = $group->create_record('invitation', {'email' => $email});
          $invitation->reset_invitation_code_and_save(user => $admin);
        }

        ## send an email to the invitee
        $mailer->send_group_invitation_email_to_new_user($group, $admin, $email, $invitation);
      }
    }

    return $self->ajax_redirect($hub->url({
      'action'    => 'Groups',
      'function'  => 'View',
      'id'        => $group_id,
      'msg'       => MESSAGE_GROUP_INVITATION_SENT,
      'emails'    => join(', ', @$valid_emails)
    }));
  }
}

1;

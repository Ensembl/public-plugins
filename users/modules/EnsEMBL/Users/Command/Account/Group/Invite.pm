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

package EnsEMBL::Users::Command::Account::Group::Invite;

### Command module to send invitation emails for a group to one or more users

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_GROUP_NOT_FOUND MESSAGE_EMAILS_INVALID MESSAGE_GROUP_INVITATION_SENT);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $r_user      = $hub->user->rose_object;
  my $group_id    = $hub->param('group_id');

  my $group       = $group_id ? $object->fetch_active_group_for_user($r_user, $group_id, {'query' => ['level' => 'administrator']}) : undef
    or return $self->ajax_redirect($hub->url({'action' => 'Groups', 'function' => 'Invite', 'err' => MESSAGE_GROUP_NOT_FOUND}));

  # validate the emails, separate the invalid ones
  my $invalid_emails  = [];
  my $valid_emails    = [ grep {$_ ne $r_user->email} map { $self->validate_fields({'email' => $_ || ''})->{'email'} || push(@$invalid_emails, $_) && () } sort keys %{{ map {$_ =~ s/^\s*|\s*$//g; $_ ? ($_ => 1) : ()} split ',', $hub->param('emails') || '' }} ];

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

    my $mailer = $self->mailer;
    foreach my $email (@$valid_emails) {

      # for an existing ensembl user
      if (my $invitee = $object->fetch_user_by_email($email)) {

        my $membership = $group->membership($invitee);

        # ignore these cases
        next if $membership->is_group_blocked || $membership->is_active;

        if ($membership->is_pending_request) { # just activate the membership and skip sending email
          $membership->activate;
          $membership->save('user' => $r_user)
        } else {
          $membership->make_invitation;
          $mailer->send_group_invitation_email_to_existing_user($group, $invitee) if $membership->save('user' => $r_user);
        }

      # for a new user (unregistered email)
      } else {

        ## create a group record invitation
        my ($invitation) = @{$group->records({'type' => 'invitation', 'code' => $email})};
        if ($invitation) {
          $invitation->save('user' => $r_user);
        } else {
          $invitation = $group->add_record({'type' => 'invitation', 'code' => $email});
          $invitation->reset_invitation_code_and_save('user' => $r_user);
        }
        $group->has_changes(1);

        ## send an email to the invitee
        $mailer->send_group_invitation_email_to_new_user($group, $email, $invitation);
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

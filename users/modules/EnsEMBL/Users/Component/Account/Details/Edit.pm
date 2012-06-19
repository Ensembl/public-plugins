package EnsEMBL::Users::Component::Account::Details::Edit;

### Page allowing user to edit his details
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $email       = $user->email;
  my $form        = $self->new_form({'action' => {qw(action Details function Save)}});
  my $email_note  = '';

  $_->type eq 'local' && $_->identity eq $email and $email_note = sprintf('You use this email to login to %s.<br />', $self->site_name) and last for @{$user->logins};

  $self->add_user_details_fields($form, {
    'email'         => $email,
    'name'          => $user->name,
    'organisation'  => $user->organisation,
    'country'       => $user->country,
    'no_list'       => 1,
    'button'        => 'Save',
    'email_notes'   => $email_note . 'If email address is changed, an email will be sent to the new address for verification purposes.'
  });

  return $self->js_section({'id' => 'edit_details', 'subsections' => [ $form->render ]});
}

1;
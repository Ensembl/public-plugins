package EnsEMBL::Users::Component::Account::Details::Edit;

### Page allowing user to edit his details
### @author hr5

use strict;
use warnings;

use base qw(EnsEMBL::Users::Component::Account);

use constant JS_CLASS_CHANGE_EMAIL => '_change_email';

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $user            = $hub->user;
  my $email           = $user->email;
  my $form            = $self->new_form({'action' => {qw(action Details function Save)}, 'csrf_safe' => 1});
  my $js_change_email = $self->JS_CLASS_CHANGE_EMAIL;
  my $email_note      = '';

  $_->type eq 'local' && $_->identity eq $email and $email_note = sprintf('You use this email to login to %s.<br />', $self->site_name) and last for @{$user->logins};

  $form->add_field({
    'label'         => 'Email Address',
    'notes'         => qq(<div class="hidden $js_change_email">${email_note}An email will be sent to the new address for verification purposes if email address is changed.</div>),
    'elements'      => [{
      'type'          => 'noedit',
      'element_class' => $js_change_email,
      'value'         => qq($email <a href="#ChangeEmail" class="small $js_change_email">Change</a>),
      'no_input'      => 1,
      'is_html'       => 1
    }, {
      'type'          => 'email',
      'name'          => 'email',
      'value'         => $email,
      'no_asterisk'   => 1,
      'shortnote'     => qq(<a href="#Cancel" class="small $js_change_email hidden">Cancel</a>),
      'element_class' => qq($js_change_email hidden)
    }]
  });

  $self->add_user_details_fields($form, {
    'name'          => $user->name,
    'organisation'  => $user->organisation,
    'country'       => $user->country,
    'no_list'       => 1,
    'no_email'      => 1,
    'button'        => 'Save',
  });

  $form->fieldset->fields->[-1]->add_element({
    'type'      => 'reset',
    'value'     => 'Cancel',
    'class'     => $self->_JS_CANCEL
  }, 1);
  
  $form->add_hidden({'name' => $self->_JS_CANCEL, 'value' => $hub->PREFERENCES_PAGE});

  return $self->js_section({'subsections' => [ $form->render ], 'js_panel' => 'AccountForm'});
}

1;
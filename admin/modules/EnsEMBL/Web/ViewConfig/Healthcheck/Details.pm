package EnsEMBL::Web::ViewConfig::Healthcheck::Details;

use strict;

sub init {
  my $self = shift;

  $self->set_defaults({
    result_INFO                => 'on',
    result_WARNING             => 'on',
    result_PROBLEM             => 'on',
    unannotated                => 'yes',
    tc_note                    => 'on',
    tc_under_review            => 'on',
    tc_healthcheck_bug         => 'off',
    tc_manual_ok               => 'off',
    tc_manual_ok_this_assembly => 'off',
    tc_manual_ok_all_releases  => 'off',
  });
}

sub form {
  my $self = shift;

  $self->add_form_element({
    type  => 'SubHeader',
    value => 'Show results of type',
  });
  
  $self->add_form_element({
    name  => 'result_INFO',
    type  => 'AltCheckBox',
    notes => 'INFO',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'result_WARNING',
    type  => 'AltCheckBox',
    notes => 'WARNING',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'result_PROBLEM',
    type  => 'AltCheckBox',
    notes => 'PROBLEM',
    value => 'on',
  });

  $self->add_form_element({
    name   => 'unannotated',
    label  => 'Show unannotated testcases',
    type   => 'DropDown',
    values => [
      { name => 'Yes', value => 'yes' },
      { name => 'No',  value => 'no'  },
    ],
  });

  $self->add_form_element({
    type  => 'SubHeader',
    value => "Show testcases with 'Action' of",
  });
  
  $self->add_form_element({
    name  => 'tc_note',
    type  => 'AltCheckBox',
    notes => 'Note',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'tc_under_review',
    type  => 'AltCheckBox',
    notes => 'Under review',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'tc_healthcheck_bug',
    type  => 'AltCheckBox',
    notes => 'Healthcheck bug',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'tc_manual_ok',
    type  => 'AltCheckBox',
    notes => 'Manual - OK',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'tc_manual_ok_this_assembly',
    type  => 'AltCheckBox',
    notes => 'Manual - OK this assembly',
    value => 'on',
  });
  
  $self->add_form_element({
    name  => 'tc_manual_ok_all_releases',
    type  => 'AltCheckBox',
    notes => 'Manual - OK all releases',
    value => 'on',
  });
}

1;

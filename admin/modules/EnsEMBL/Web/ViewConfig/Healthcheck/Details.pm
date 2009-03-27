package EnsEMBL::Web::ViewConfig::Healthcheck::Details;

use strict;
use warnings;
no warnings 'uninitialized';

sub init {
  my $view_config = shift;

  $view_config->_set_defaults(qw/
    result_INFO                 on
    result_WARNING              on
    result_PROBLEM              on
    unannotated                 yes
    tc_note                     on
    tc_under_review             on
    tc_healthcheck_bug          off
    tc_manual_ok                off
    tc_manual_ok_this_assembly  off
    tc_manual_ok_all_releases   off
  /);

  $view_config->storable = 1;
}

sub form {
  my( $view_config, $object ) = @_;

  $view_config->add_fieldset('Display Options');

  $view_config->add_form_element({
    'type'    => 'SubHeader',
    'value'   => 'Show results of type',
  });
  $view_config->add_form_element({
    'name'    => 'result_INFO',
    'type'    => 'AltCheckBox',
    'notes'   => 'INFO',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'result_WARNING',
    'type'    => 'AltCheckBox',
    'notes'   => 'WARNING',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'result_PROBLEM',
    'type'    => 'AltCheckBox',
    'notes'   => 'PROBLEM',
    'value'   => 'on',
  });

  $view_config->add_form_element({
    'name'    => 'unannotated',
    'label'   => 'Show unannotated testcases',
    'type'    => 'DropDown',
    'values'  => [
        {'name' => 'Yes', 'value' => 'yes'},
        {'name' => 'No', 'value' => 'no'},
    ],
  });

  $view_config->add_form_element({
    'type'    => 'SubHeader',
    'value'   => "Show testcases with 'Action' of",
  });
  $view_config->add_form_element({
    'name'    => 'tc_note',
    'type'    => 'AltCheckBox',
    'notes'   => 'Note',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'tc_under_review',
    'type'    => 'AltCheckBox',
    'notes'   => 'Under review',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'tc_healthcheck_bug',
    'type'    => 'AltCheckBox',
    'notes'   => 'Healthcheck bug',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'tc_manual_ok',
    'type'    => 'AltCheckBox',
    'notes'   => 'Manual - OK',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'tc_manual_ok_this_assembly',
    'type'    => 'AltCheckBox',
    'notes'   => 'Manual - OK this assembly',
    'value'   => 'on',
  });
  $view_config->add_form_element({
    'name'    => 'tc_manual_ok_all_releases',
    'type'    => 'AltCheckBox',
    'notes'   => 'Manual - OK all releases',
    'value'   => 'on',
  });

}

1;

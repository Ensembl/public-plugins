=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

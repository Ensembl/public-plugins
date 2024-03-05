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

package EnsEMBL::ORM::Command::DbFrontend::Save;

### NAME: EnsEMBL::ORM::Command::DbFrontend::Save
### Module to save ORM::EnsEMBL::Rose::Object contents back to the database

### STATUS: Under Development

### DESCRIPTION:
### This module saves an object for the dbfrontend object that has been edited via form

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Command);

sub process {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $done      = $object->save;
  my $function  = $hub->function || '';
  
  $self->ajax_redirect($hub->url($done && @$done
    ? $object->is_ajax_request ? {'action' => 'Display', 'function' => $function, 'id' => $object->rose_object->get_primary_key_value} : {'action' => $object->default_action, 'function' => $function}
    : {'action' => 'Problem', 'function' => $function, 'error' => $object->rose_error}
  ));
}

1;

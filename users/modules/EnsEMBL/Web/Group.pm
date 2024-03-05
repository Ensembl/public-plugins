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

package EnsEMBL::Web::Group;

### Wrapper around ORM::EnsEMBL::DB::Accounts::Object::Group for use in the web code

use strict;
use warnings;

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::Exceptions qw(WebException);

use parent qw(EnsEMBL::Web::RecordManagerRose);

sub user :Accessor; ## Gets the linked EnsEMBL::Web::User object

sub init {
  ## Abstract method implementation
  ## @param Rose object
  ## @param Currently logged in user
  my ($self, $group, $user) = @_;

  throw WebException('Invalid/missing Group object') if !$group || !ref $group || !UNIVERSAL::isa($group, 'ORM::EnsEMBL::DB::Accounts::Object::Group');
  throw WebException('Invalid/missing User object')  if !$user  || !ref $user  || !UNIVERSAL::isa($user,  'EnsEMBL::Web::User');

  $self->{'rose_object'} = $group;
  $self->{'user'}        = $user;

  return $self;
}

sub record_rose_manager {
  ## Abstract method implementation
  return 'ORM::EnsEMBL::DB::Accounts::Manager::Record';
}

sub record_type {
  ## Abstract method implementation
  return 'group';
}

sub record_type_id {
  ## Abstract method implementation
  return shift->group_id;
}

sub _save_record {
  ## @override
  ## @private
  ## Saves a record and set created_by/modified_by fields
  my ($self, $record, $args) = @_;

  $args ||= {};

  $args->{'user'} ||= $self->user;

  return $self->SUPER::_save_record($record, $args);
}


1;

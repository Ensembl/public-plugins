=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::User;

use strict;
use warnings;

use EnsEMBL::Web::Record;
use EnsEMBL::Web::Group;
use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::Exceptions qw(WebException);

use ORM::EnsEMBL::DB::Accounts::Manager::User;
use ORM::EnsEMBL::DB::Accounts::Manager::Record;

use parent qw(EnsEMBL::Web::RecordManagerRose);

use overload qw("" to_string bool to_boolean);

sub init {
  ## Abstract method implementation
  my $self  = shift;
  my $hub   = $self->hub;

  # retrieve existing user cookie or create a new one
  $self->{'_user_cookie'} = $hub->get_cookie($SiteDefs::ENSEMBL_USER_COOKIE, 1);

  if (my $user_id = $self->{'_user_cookie'}->value) {
    $self->authorise({'id' => $user_id});
  }
}

sub record_rose_manager {
  ## Abstract method implementation
  return 'ORM::EnsEMBL::DB::Accounts::Manager::Record';
}

sub record_type {
  ## Abstract method implementation
  return 'user';
}

sub record_type_id {
  ## Abstract method implementation
  return shift->user_id;
}

sub store_records {
  ## @override
  my ($self, $force) = @_;

  if ($self->_groups_fetched) {
    for (@{$self->groups}) {
      if ($_->has_changes) {
        $force = 1;
        last;
      }
    }
  }

  return $self->SUPER::store_records($force);
}

sub user_id {
  ## Gets the id of the user if logged in
  my $self = shift;

  if (!exists $self->{'_user_id'}) {
    $self->{'_user_id'} = $self->rose_object ? $self->rose_object->user_id : '';

    # user id is retrieved, set auto commit off
    $self->_begin_transaction if $self->{'_user_id'};
  }

  return $self->{'_user_id'};
}

sub authorise {
  ## Initialising the actual authenticated rose user object
  ## @param Hashref with the following keys
  ##  - user        : Rose user object
  ##  - id          : User id (required only if 'user' key is missing)
  ##  - set_cookie  : Flag if on, will set the user cookie
  ## @return 1 if successful, 0 otherwise
  ## @exception ORMException if db could not connect, WebException if neither user nor id is provided
  my ($self, $params) = @_;
  my $user = delete $params->{'user'};

  unless ($user) {
    throw WebException('Either user id or rose user object is required to initialise EnsEMBL::Web::User object') unless $params->{'id'};
    $user = ORM::EnsEMBL::DB::Accounts::Manager::User->get_by_id($params->{'id'});
  }

  return 0 unless $user;

  $self->{'rose_object'} = $user;
  $self->{'_user_cookie'}->bake($user->user_id) if $params->{'set_cookie'};

  return 1;
}

sub deauthorise {
  ## Clears the rose user saved inside the object, and the user cookie
  ## @return No return value
  my $self = shift;

  $self->{'rose_object'} = undef;
  $self->{'_user_cookie'}->clear;
}

sub groups {
  ## Gets all the active groups user is an active memeber of
  ## @return Arrayref of Rose Group objects
  my $self = shift;
  return $self->{'_groups'} ||= [ map EnsEMBL::Web::Group->new($self->hub, $_->group), @{$self->rose_object->active_memberships} ];
}

sub user_rose_manager {
  ## Gets the manager class used to access user table
  return 'ORM::EnsEMBL::DB::Accounts::Manager::User';
}

sub default_salt {
  ## Gets the default value for 'salt' column in user table
  manager_class->object_class->DEFAULT_SALT;
}

sub to_string {
  ## Used to operator overloading
  ## @return ID of the user if logged in, empty string otherwise
  return $_[0]->rose_object ? shift->user_id : '';
}

sub to_boolean {
  ## Used to operator overloading
  ## @return 1 if user logged in, 0 otherwise
  return shift->rose_object ? 1 : 0;
}

sub _groups_fetched {
  ## @private
  return exists shift->{'_groups'} ? 1 : 0;
}

sub favourite_species {
  ## Gets all the species favourited by the user
  ## @return ArrayRef of species name
  my $self            = shift;
  my $species_defs    = $self->hub->species_defs;
  my %valid_species   = map { $_ => 1 } $species_defs->valid_species;
  my ($species_list)  = @{$self->specieslists};
  my @favourites      = $species_list ? grep($valid_species{$_}, split ',', $species_list->favourites) : ();
  return \@favourites;
}



















sub _goto_rose_object {throw WebException('usage changed');
  ## maps any methods in this class to Rose User Object class
  ## @private
  my ($self, $method, @args) = @_;
  return $self->rose_object ? $self->rose_object->$method(@args) : undef;
}

sub get_record {throw WebException('usage changed');
  ## Gets a record from its record id
  ## @return Rose Record object
  my ($self, $record_id) = @_;
  return $self->rose_object->find_records('query' => ['record_id' => $record_id], 'limit' => 1)->[0];
}








sub password              { shift->_goto_rose_object('password', @_);       }
sub create_record         { shift->_goto_rose_object('create_record', @_);  }

# sub logins                { shift->_goto_rose_object('logins');             }
# sub records               { shift->_goto_rose_object('records');            }
sub annotations           { shift->_goto_rose_object('annotations');        }
sub newsfilters           { shift->_goto_rose_object('newsfilters');        }
# sub specieslists          { shift->_goto_rose_object('specieslists');       }
# sub histories             { shift->_goto_rose_object('histories');          }
sub favourite_tracks      { shift->_goto_rose_object('favourite_tracks');   }

sub is_admin_of           { shift->_goto_rose_object('is_admin_of', @_);    }
sub is_member_of          { shift->_goto_rose_object('is_member_of', @_);   }








#################################################
###########                        ##############
########### Backward compatibility ##############
###########                        ##############
#################################################

sub get_groups {throw WebException('usage changed');
  return @{shift->groups};
}

sub get_group {throw WebException('usage changed');
  my ($self, $group_id) = @_;
  my $membership = $self->rose_object->get_membership_object($group_id);
  return $membership ? $membership->group : undef;
}

sub get_records {throw WebException('usage changed');
  my ($self, $record_type) = @_;
  return EnsEMBL::Web::Record->from_rose_objects($self->$record_type || []);
}

sub get_group_records {throw WebException('usage changed');
  my ($self, $group, $record_type) = @_;
  $record_type ||= 'records';
  return EnsEMBL::Web::Record->from_rose_objects($group->$record_type || []);
}

sub get_group_record {throw WebException('usage changed');
  my ($self, $group, $record_id) = @_;
  my ($record) = EnsEMBL::Web::Record->from_rose_objects($group->find_records('query' => ['record_id' => $record_id], 'limit' => 1) || []);
  return $record;
}

sub find_admin_groups {throw WebException('usage changed');
  return map $_->group, @{shift->rose_object->admin_memberships};
}

sub _add_to_records {throw WebException('usage changed');
  my ($self, $record_type) = splice @_, 0, 2;

  my $data = ref $_[0] eq 'HASH' ? $_[0] : {@_};

  my $record = $self->create_record($record_type, $data);
  $record->save('user' => $self->rose_object);

  ($record) = EnsEMBL::Web::Record->from_rose_objects([$record]);

  return $record;
}

sub add_to_uploads {throw WebException('usage changed');
  return shift->_add_to_records('upload', @_);
}

sub add_to_urls {throw WebException('usage changed');
  return shift->_add_to_records('url', @_);
}

sub _records {throw WebException('usage changed');
  my ($self, $type, $id) = @_;
  return $self->rose_object ? $self->rose_object->find_records('query' => [ 'type' => $type, $id ? ('record_id' => $id) : () ]) : ();
}

sub uploads {throw WebException('usage changed'); return shift->_records('upload', @_); }
sub urls    {throw WebException('usage changed'); return shift->_records('url', @_); }

sub get_favourite_tracks {throw WebException('usage changed');
  my $self   = shift;
  my ($data) = map $_->{'tracks'}, $self->get_records('favourite_tracks');

  return $data || {};
}

sub set_favourite_tracks {throw WebException('usage changed');
  my ($self, $data) = @_;
  my ($favourites)  = @{$self->favourite_tracks};
      $favourites ||= $self->create_record('favourite_tracks');

  if ($data) {
    $favourites->tracks($data);
    $favourites->save('user' => $self->rose_object);
  } else {
    $favourites->delete if $favourites->get_primary_key_value;
  }
}

sub id          :Deprecated('use user_id method') { shift->user_id; }


1;

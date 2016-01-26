=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::Record;
use EnsEMBL::Web::Exceptions;

use ORM::EnsEMBL::DB::Accounts::Manager::User;
use ORM::EnsEMBL::DB::Accounts::Manager::Record;

use overload qw("" to_string bool to_boolean);

sub rose_object           { return shift->{'_user'};    } ## @return Rose User object
sub hub                   { return shift->{'_hub'};     } ## @return Hub
sub cookie                { return shift->{'_cookie'};  } ## @return User cookie

sub display_name          { return encode_entities(shift->name);                                                      } ## @return HTML escaped name
sub display_email         { return encode_entities(shift->email);                                                     } ## @return HTML escaled email address
sub display_organisation  { return encode_entities(shift->organisation || '');                                        } ## @return HTML escaped organisation name
sub display_country       { return encode_entities($_[0]->hub->species_defs->COUNTRY_CODES->{$_[0]->country || ''});  } ## @return displayable country name

sub id                    { shift->_goto_rose_object('user_id', @_);        } # TODO remove this extra method
sub user_id               { shift->_goto_rose_object('user_id', @_);        }
sub name                  { shift->_goto_rose_object('name', @_);           }
sub email                 { shift->_goto_rose_object('email', @_);          }
sub salt                  { shift->_goto_rose_object('salt', @_);           }
sub password              { shift->_goto_rose_object('password', @_);       }
sub organisation          { shift->_goto_rose_object('organisation', @_);   }
sub country               { shift->_goto_rose_object('country', @_);        }
sub status                { shift->_goto_rose_object('status', @_);         }
sub create_record         { shift->_goto_rose_object('create_record', @_);  }

sub logins                { shift->_goto_rose_object('logins');             }
sub records               { shift->_goto_rose_object('records');            }
sub bookmarks             { shift->_goto_rose_object('bookmarks');          }
sub annotations           { shift->_goto_rose_object('annotations');        }
sub newsfilters           { shift->_goto_rose_object('newsfilters');        }
sub specieslists          { shift->_goto_rose_object('specieslists');       }
sub histories             { shift->_goto_rose_object('histories');          }
sub favourite_tracks      { shift->_goto_rose_object('favourite_tracks');   }

sub is_admin_of           { shift->_goto_rose_object('is_admin_of', @_);    }
sub is_member_of          { shift->_goto_rose_object('is_member_of', @_);   }

sub manager_class         { 'ORM::EnsEMBL::DB::Accounts::Manager::User';    }
sub default_salt          { manager_class->object_class->DEFAULT_SALT;      }

## Temporary method added to get rid of the use of hub->user instead of the actual rose object user
sub get_primary_key_value { use Carp; carp q(User plugin error: 'user' argument needs to be $hub->user->rose_object instead of $hub->user); return shift->user_id; }

sub new {
  ## @constructor
  ## @param Hub
  ## @param Cookie object
  ## @exception ORMException if thrown by authorise method
  my ($class, $hub, $cookie) = @_;

  my $self = bless {
    '_user'   => undef,
    '_hub'    => $hub,
    '_cookie' => $cookie
  }, $class;

  if (my $user_id = $cookie->value) {
    $self->authorise({'id' => $user_id});
  }

  return $self;
}

sub authorise {
  ## Initialising the actual authenticated rose user object
  ## @param Hashref with the following keys
  ##  - user        : Rose user object
  ##  - id          : User id (required only if 'user' key is missing)
  ##  - set_cookie  : Flag if on, will set the user cookie
  ## @return 1 if successful, 0 otherwise
  ## @exception ORMException if db could not connect, InvalidArgumentException if neither user nor id is provided
  my ($self, $params) = @_;
  my $user = delete $params->{'user'};

  unless ($user) {

    throw exception('UserException::InvalidArgumentException', 'At least one out of user id and rose user object is required to initialise EnsEMBL::Web::User object') unless $params->{'id'};
    $user = ORM::EnsEMBL::DB::Accounts::Manager::User->get_by_id($params->{'id'});
  }

  return 0 unless $user;

  $self->{'_user'} = $user;
  $self->cookie->bake($user->user_id) if $params->{'set_cookie'};

  return 1;
}

sub deauthorise {
  ## Clears the rose user saved inside the object, and the user cookie
  ## @return No return value
  my $self = shift;
  $self->cookie->clear;
  $self->{'_user'} = undef;
}

sub groups {
  ## Gets all the active groups user is an active memeber of
  ## @return Arrayref of Rose Group objects
  my $self = shift;
  return [ map $_->group, @{$self->rose_object->active_memberships} ];
}

sub get_record {
  ## Gets a record from its record id
  ## @return Rose Record object
  my ($self, $record_id) = @_;
  return $self->rose_object->find_records('query' => ['record_id' => $record_id], 'limit' => 1)->[0];
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

sub _goto_rose_object {
  ## maps any methods in this class to Rose User Object class
  ## @private
  my ($self, $method, @args) = @_;
  return $self->rose_object ? $self->rose_object->$method(@args) : undef;
}


#################################################
###########                        ##############
########### Backward compatibility ##############
###########                        ##############
#################################################

sub get_groups {
  return @{shift->groups};
}

sub get_group {
  my ($self, $group_id) = @_;
  my $membership = $self->rose_object->get_membership_object($group_id);
  return $membership ? $membership->group : undef;
}

sub get_records {
  my ($self, $record_type) = @_;
  return EnsEMBL::Web::Record->from_rose_objects($self->$record_type || []);
}

sub get_group_records {
  my ($self, $group, $record_type) = @_;
  $record_type ||= 'records';
  return EnsEMBL::Web::Record->from_rose_objects($group->$record_type || []);
}

sub get_group_record {
  my ($self, $group, $record_id) = @_;
  my ($record) = EnsEMBL::Web::Record->from_rose_objects($group->find_records('query' => ['record_id' => $record_id], 'limit' => 1) || []);
  return $record;
}

sub find_admin_groups {
  return map $_->group, @{shift->rose_object->admin_memberships};
}

sub _add_to_records {
  my ($self, $record_type) = splice @_, 0, 2;

  my $data = ref $_[0] eq 'HASH' ? $_[0] : {@_};

  my $record = $self->create_record($record_type, $data);
  $record->save('user' => $self->rose_object);

  ($record) = EnsEMBL::Web::Record->from_rose_objects([$record]);

  return $record;
}

sub add_to_uploads {
  return shift->_add_to_records('upload', @_);
}

sub add_to_urls {
  return shift->_add_to_records('url', @_);
}

sub _records {
  my ($self, $type, $id) = @_;
  return $self->rose_object ? $self->rose_object->find_records('query' => [ 'type' => $type, $id ? ('record_id' => $id) : () ]) : ();
}

sub uploads { return shift->_records('upload', @_); }
sub urls    { return shift->_records('url', @_); }

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

sub get_favourite_tracks {
  my $self   = shift;
  my ($data) = map $_->{'tracks'}, $self->get_records('favourite_tracks');

  return $data || {};
}

sub set_favourite_tracks {
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

1;

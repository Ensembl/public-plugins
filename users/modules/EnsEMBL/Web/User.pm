package EnsEMBL::Web::User;

use strict;
use warnings;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::Record;
use EnsEMBL::Web::DASConfig;
use EnsEMBL::Web::Exceptions;

use EnsEMBL::ORM::Rose::Manager::User;
use EnsEMBL::ORM::Rose::Manager::Record;

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
sub dases                 { shift->_goto_rose_object('dases');              }
sub newsfilters           { shift->_goto_rose_object('newsfilters');        }
sub specieslists          { shift->_goto_rose_object('specieslists');       }
sub histories             { shift->_goto_rose_object('histories');          }
sub favourite_tracks      { shift->_goto_rose_object('favourite_tracks');   }
                          
sub is_admin_of           { shift->_goto_rose_object('is_admin_of', @_);    }
sub is_member_of          { shift->_goto_rose_object('is_member_of', @_);   }

sub default_salt          { EnsEMBL::ORM::Rose::Manager::User->object_class->DEFAULT_SALT; }

sub new {
  ## @constructor
  ## @param Hub
  ## @param Cookie object
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
  ## @param Hashref with one out of the following keys
  ##  - id          : User id
  ##  - user        : Rose user object
  ##  - set_cookie  : Flag if on, will set the user cookie
  ## @return 1 if successful, 0 otherwise
  ## @exception InvalidArgumentException - if neither of id or user is provided
  my ($self, $params) = @_;
  my $user = delete $params->{'user'};

  unless ($user) {

    throw exception('UserException::InvalidArgumentException', 'At least one out of user id and rose user object is required to initialise EnsEMBL::Web::User object') unless $params->{'id'};
    $user = EnsEMBL::ORM::Rose::Manager::User->get_by_id($params->{'id'}) if $self->hub->species_defs->has_userdb;
  }

  return 0 unless $user;

  $self->{'_user'} = $user;
  $self->cookie->bake($user->user_id) if $params->{'set_cookie'};

  return 1;
}

sub groups {
  ## Gets all the active groups user is an active memeber of
  ## @return Arrayref of Rose Group objects
  my $self = shift;
  return [ map $_->group, @{$self->rose_object->active_memberships} ];
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

sub deauthorise {
  ## Clears the rose user saved inside the object, and the user cookie
  ## @return No return value
  my $self = shift;
  $self->cookie->clear;
  $self->{'_user'} = undef;
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

sub get_record {
  my ($self, $record_id) = @_;
  my $records   = $self->rose_object->find_records('query' => ['record_id' => $record_id], 'limit' => 1);
  my ($record)  = $records && @$records ? EnsEMBL::Web::Record->from_rose_objects($records) : ();
  return $record;
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
  $record->save('user' => $self);

  ($record) = EnsEMBL::Web::Record->from_rose_objects([$record]);

  return $record;
}

sub add_to_uploads {
  return shift->_add_to_records('upload', @_);
}

sub add_to_urls {
  return shift->_add_to_records('url', @_);
}

sub add_to_dases {
  return shift->_add_to_records('das', @_);
}

sub _records {
  my ($self, $type, $id) = @_;
  return $self->rose_object ? $self->rose_object->find_records('query' => [ 'type' => $type, $id ? ('record_id' => $id) : () ]) : ();
}

sub uploads { return shift->_records('upload', @_); }
sub urls    { return shift->_records('url', @_); }

sub get_all_das {
  my $self    = shift;
  my $species = shift || $ENV{'ENSEMBL_SPECIES'};

  $species = '' if $species eq 'common';

  my %by_name = ();
  my %by_url  = ();
  for my $das_record ( $self->get_records('dases') ) {
    # Create new DAS source from value in database...
    my $das = EnsEMBL::Web::DASConfig->new_from_hashref( $das_record->data );
    $das->matches_species( $species ) || next;
    $das->category( 'user' );
    $by_name{ $das->logic_name } = $das;
    $by_url { $das->full_url   } = $das;
  }
  
  return wantarray ? ( \%by_name, \%by_url ) : \%by_name;
}

sub add_das {
  ## Adds a DAS config to user records
  ## @param EnsEMBL::Web::DASConfig
  ## @return Record for saved das config, undef if invalid DASConfig or saving unsuccessful
  my ($self, $das) = @_;
  my $das_record;

  if ($das && ref $das && ref $das eq 'EnsEMBL::Web::DASConfig') {
    $das->category('user');
    $das->mark_altered();

    $das_record = $self->create_record('das');
    $das_record->data($das);
    $das_record->save('user' => $self);
  }
  return $das_record;
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
    $favourites->save('user' => $self);
  } else {
    $favourites->delete if $favourites->get_primary_key_value;
  }
}

sub find_administratable_groups {
  warn "Method find_administratable_groups should not be called -";
}

sub find_nonadmin_groups {
  warn "Method find_nonadmin_groups should not be called -";
}

sub update_invitations {
  warn "Method update_invitations should not be called -";
}

1;

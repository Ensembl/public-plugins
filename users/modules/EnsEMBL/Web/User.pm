package EnsEMBL::Web::User;

use strict;
use warnings;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::DASConfig;
use EnsEMBL::Web::Exceptions;
use EnsEMBL::ORM::Rose::Manager::User;
use EnsEMBL::ORM::Rose::Manager::Record;

use base qw(EnsEMBL::Web::Root); ##  TODO ??

use overload qw("" to_string bool to_boolean);

sub rose_object           { return shift->{'_user'};                                                                  } ## @return Rose User object
sub hub                   { return shift->{'_hub'};                                                                   } ## @return Hub
sub cookie                { return shift->{'_cookie'};                                                                } ## @return User cookie

sub display_name          { return encode_entities(shift->name);                                                      } ## @return HTML escaped name
sub display_email         { return encode_entities(shift->email);                                                     } ## @return HTML escaled email address
sub display_organisation  { return encode_entities(shift->organisation || '');                                        } ## @return HTML escaped organisation name
sub display_country       { return encode_entities($_[0]->hub->species_defs->COUNTRY_CODES->{$_[0]->country || ''});  } ## @return displayable country name

sub id                    { shift->user_id;                                 }
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
sub configurations        { shift->_goto_rose_object('configurations');     }
sub annotations           { shift->_goto_rose_object('annotations');        }
sub dases                 { shift->_goto_rose_object('dases');              }
sub newsfilters           { shift->_goto_rose_object('newsfilters');        }
sub sortables             { shift->_goto_rose_object('sortables');          }
sub currentconfigs        { shift->_goto_rose_object('currentconfigs');     }
sub specieslists          { shift->_goto_rose_object('specieslists');       }
sub uploads               { shift->_goto_rose_object('uploads');            }
sub urls                  { shift->_goto_rose_object('urls');               }
sub histories             { shift->_goto_rose_object('histories');          }
sub favourite_tracks      { shift->_goto_rose_object('favourite_tracks');   }
                          
sub is_admin_of           { shift->_goto_rose_object('is_admin_of');        }
sub is_member_of          { shift->_goto_rose_object('is_member_of');       }

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
  ##  - id    : User id
  ##  - user  : Rose user object
  ## @return 1 if successful, 0 otherwise
  ## @exception InvalidArgumentException - if neither of id or user is provided
  my ($self, $params) = @_;
  my $user = delete $params->{'user'};

  unless ($user) {

    throw exception('UserException::InvalidArgumentException', 'At least one out of user id and rose user object is required to initialise EnsEMBL::Web::User object') unless $params->{'id'};
    $user = EnsEMBL::ORM::Rose::Manager::User->get_by_id($params->{'id'});
  }

  return 0 unless $user;

  $self->{'_user'} = $user;
  $self->cookie->bake($user->user_id);

  return 1;
}

sub groups {
  ## Gets all the active groups user is an active memeber of
  my $self = shift;
  return [ map $_->group, @{$self->rose_object->active_memberships} ];
}

sub to_string {
  return $_[0]->rose_object ? shift->user_id : '';
}

sub to_boolean {
  return shift->rose_object ? 1 : 0;
}

sub deauthorise {
  ## Clears the rose user saved inside the object, and the user cookie
  my $self = shift;
  $self->cookie->clear;
  $self->{'_user'} = undef;
}

#TODO - check if login logout works + other integration

sub _goto_rose_object {
  ## @private
  my ($self, $method, @args) = @_;
  return $self->rose_object ? $self->rose_object->$method(@args) : undef;
}





# Backward compatiablity #
sub get_all_das {
  my $self    = shift;
  my $species = shift || $ENV{'ENSEMBL_SPECIES'};

  $species = '' if $species eq 'common';

  my %by_name = ();
  my %by_url  = ();
  for my $das_record ( @{$self->dases} ) {
    # Create new DAS source from value in database...
    my $das = EnsEMBL::Web::DASConfig->new_from_hashref( $das_record->data->raw );
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

    $das_record = $self->{'_user'}->create_record('das');
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
  return {};
  my ($data) = map $_->{'tracks'}, @{$self->favourite_tracks};
     $data   = eval($data) if $data;
  
  return $data || {};
}

1;
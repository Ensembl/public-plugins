package EnsEMBL::ORM::Rose::Object::RecordOwner;

### NAME: EnsEMBL::ORM::Rose::Object::RecordOwner
### Base class for the group, user table in user database (since both group and user can own a record)

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant {
  ROSE_DB_NAME  => 'user',
  RECORD_TYPE   => ''
};

sub create_record {
  ## Creates a record of a given type (does not save it to the db)
  ## @param Type of the record
  ## @param Hashref of name value pair for columns of the new object (optional)
  my ($self, $type, $params) = @_;

  return ($self->add_records([{
    %{$params || {}},
    'type'            => $type,
    'record_type'     => $self->RECORD_TYPE,
    'record_type_id'  => $self->get_primary_key_value
  }]))[0];
}

sub record_relationship_types {
  ## @protected
  return [
    annotations           => { 'relationship' => 'records', 'condition' => {'type' => 'annotation'}       },
    bookmarks             => { 'relationship' => 'records', 'condition' => {'type' => 'bookmark'}         },
    dases                 => { 'relationship' => 'records', 'condition' => {'type' => 'das'}              },
    favourite_tracks      => { 'relationship' => 'records', 'condition' => {'type' => 'favourite_tracks'} },
    histories             => { 'relationship' => 'records', 'condition' => {'type' => 'history'}          },
    invitations           => { 'relationship' => 'records', 'condition' => {'type' => 'invitation'}       }, # this record only contains the invitations for the users who have not yet registered with ensembl, invitations for existing users are saved as Membership objects
    newsfilters           => { 'relationship' => 'records', 'condition' => {'type' => 'newsfilter'}       },
    specieslists          => { 'relationship' => 'records', 'condition' => {'type' => 'specieslist'}      },
    uploads               => { 'relationship' => 'records', 'condition' => {'type' => 'upload'}           },
    urls                  => { 'relationship' => 'records', 'condition' => {'type' => 'url'}              }
  ];
}

sub record_relationship_params {
  ## @protected
  my ($class, $foreign_key) = @_;
  return {
    'type'        => 'one to many',
    'class'       => 'EnsEMBL::ORM::Rose::Object::Record',
    'column_map'  => {$foreign_key => 'record_type_id'},
    'methods'     => { map {$_, undef} qw(add_on_save count find get_set_on_save)},
    'join_args'   => [ 'record_type' => $class->RECORD_TYPE ] # join_args key is not documented in Rose, so take care of this if something changes in future
  };
}

1;

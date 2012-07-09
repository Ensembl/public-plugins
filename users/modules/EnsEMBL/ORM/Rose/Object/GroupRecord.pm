package EnsEMBL::ORM::Rose::Object::GroupRecord;

### NAME: EnsEMBL::ORM::Rose::Object::GroupRecord
### ORM class for the group_record table in user database

use strict;
use warnings;

use EnsEMBL::Web::Tools::RandomString qw(random_string);

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

## Define schema
__PACKAGE__->meta->setup(
  table               => 'group_record',
  columns             => [
    group_record_id     => {
      'type'              => 'serial',
      'primary_key'       => 1,
      'not_null'          => 1
    },
    webgroup_id         => {
      'type'              => 'integer',
      'length'            => 11,
      'not_null'          => 1,
      'alias'             => 'group_id'
    },
    type                => {
      'type'              => 'varchar',
      'length'            => 255
    },
    data                => {
      'type'              => 'datamap',
      'trusted'           => 1
    }
  ],
  virtual_columns     => [
    url                 => {'column' => 'data'}, # for bookmarks
    name                => {'column' => 'data'}, # for bookmarks
    description         => {'column' => 'data'}, # for bookmarks
    click               => {'column' => 'data'}, # for bookmarks
    species             => {'column' => 'data'},
    invitation_code     => {'column' => 'data'}, # for invitations
    email               => {'column' => 'data'}, # for invitations
  ],
  relationships       => [
    group               => {
      'type'              => 'many to one',
      'class'             => 'EnsEMBL::ORM::Rose::Object::Group',
      'column_map'        => {'webgroup_id' => 'webgroup_id'},
    }
  ]
);

sub get_invitation_code {
  ## Gets a url code for invitation type group record
  ## @return Code string
  return sprintf('%s-%s', $_->invitation_code, $_->group_record_id) for @_;
}

sub reset_invitation_code_and_save {
  ## Resets the code and saves the object
  ## @params Same as save method
  my $self = shift;
  $self->invitation_code(random_string(10));
  return $self->save(@_);
}

1;
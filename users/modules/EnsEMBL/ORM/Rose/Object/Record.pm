package EnsEMBL::ORM::Rose::Object::Record;

### NAME: EnsEMBL::ORM::Rose::Object::Record
### ORM class for the record table in user db

use strict;
use warnings;

use EnsEMBL::Web::Tools::RandomString qw(random_string);

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

my $VIRTUAL_COLUMNS = {
  'history'           => [qw(object value url name species param)],
  'bookmark'          => [qw(name description url object click)],
  'specieslist'       => [qw(favourites list)],
  'urls'              => [qw(format cloned_from)],
  'invitation'        => [qw(invitation_code email)],
  'upload'            => [qw(filename filesize name code md5 format species assembly share_id analyses browser_switches style display nearest timestamp cloned_from)],
  'favourite_tracks'  => [qw(tracks)],
  'das'               => [qw(label)] #some others too, but they are not directly queried on this object (TODO)
};

my $RECORD_TABLE = $SiteDefs::ENSEMBL_USER_RECORD_TABLE || 'record';

## Define schema
__PACKAGE__->meta->setup(
  table           => $RECORD_TABLE,
  columns         => [
    record_id       => {'type' => 'serial',  'primary_key'  => 1,                 'not_null' => 1                       },
    record_type     => {'type' => 'enum',    'values'       => [qw(user group)],  'not_null' => 1, 'default' => 'user'  },
    record_type_id  => {'type' => 'integer', 'length'       => 11,                'not_null' => 1                       },
    type            => {'type' => 'varchar', 'length'       => 255                                                      },
    data            => {'type' => 'datamap', 'trusted'      => 1                                                        }
  ],

  virtual_columns => [ map {$_ => {'column' => 'data'}} keys %{{ map { map {$_ => 1} @$_ } values %$VIRTUAL_COLUMNS }} ],
  
  relationships   => [ # TODO - add 'record_type' in the query_args
    user                  => {
      'type'                => 'many to one',
      'class'               => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'          => {'record_type_id' => 'user_id'},
    },
    group                 => {
      'type'                => 'many to one',
      'class'               => 'EnsEMBL::ORM::Rose::Object::Group',
      'column_map'          => {'record_type_id' => 'webgroup_id'},
    }
  ]
);

sub get_invitation_code {
  ## For invitation record only for record_type group
  ## Gets a url code for invitation type group record
  ## @return Code string
  return sprintf('%s-%s', $_->invitation_code, $_->record_id) for @_;
}

sub reset_invitation_code_and_save {
  ## For invitation record only for record_type group
  ## Resets the code and saves the object
  ## @params Same as save method
  my $self = shift;
  $self->invitation_code(random_string(10));
  return $self->save(@_);
}

1;
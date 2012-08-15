package EnsEMBL::ORM::Rose::Object::Record;

### NAME: EnsEMBL::ORM::Rose::Object::Record
### ORM class for the record table in user db

use strict;
use warnings;

use EnsEMBL::Web::Tools::RandomString qw(random_string);

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'user';

my $VIRTUAL_COLUMNS = {
  'histroy'     => [qw(object value url name species param)],
  'extra'       => [qw(url name description click species object)],
  'bookmark'    => [qw(shortname click)],
  'specieslist' => [qw(favourites list)],
  'urls'        => [qw(format)],
  'invitation'  => [qw(invitation_code email)]
};

## Define schema
__PACKAGE__->meta->setup(
  table           => 'record',
  columns         => [
    record_id       => {'type' => 'serial',  'primary_key'  => 1,                 'not_null' => 1                       },
    owner_id        => {'type' => 'integer', 'length'       => 11,                'not_null' => 1                       },
    type            => {'type' => 'varchar', 'length'       => 255                                                      },
    owner_type      => {'type' => 'enum',    'values'       => [qw(user group)],  'not_null' => 1, 'default' => 'user'  },
    data            => {'type' => 'datamap', 'trusted'      => 1                                                        }
  ],

  virtual_columns => [ map {$_ => {'column' => 'data'}} keys %{{ map { map {$_ => 1} @$_ } values %$VIRTUAL_COLUMNS }} ],
);

sub get_invitation_code {
  ## For invitation record only for owner_type group)
  ## Gets a url code for invitation type group record
  ## @return Code string
  return sprintf('%s-%s', $_->invitation_code, $_->record_id) for @_;
}

sub reset_invitation_code_and_save {
  ## For invitation record only for owner_type group
  ## Resets the code and saves the object
  ## @params Same as save method
  my $self = shift;
  $self->invitation_code(random_string(10));
  return $self->save(@_);
}

1;
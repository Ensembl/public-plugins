package EnsEMBL::ORM::Rose::MetaData::Trackable;

## Name: EnsEMBL::ORM::Rose::MetaData::Trackable
## MetaData class for all Trackable rose Objects

use strict;

use EnsEMBL::ORM::Rose::Object::User;

use base qw(EnsEMBL::ORM::Rose::MetaData);

sub setup {
  ## @overrides
  ## Automatically adds trackable fields and relationships (external if applicable) before setup.
  ## @param Same as for inherited one
  my ($self, %params) = @_;
  
  push @{$params{'columns'}}, (
    'created_by',  { type => 'integer'  },
    'created_at',  { type => 'datetime' },
    'modified_by', { type => 'integer'  },
    'modified_at', { type => 'datetime' }
  );

  push @{$params{$self->class->ROSE_DB_NAME eq EnsEMBL::ORM::Rose::Object::User->ROSE_DB_NAME ? 'relationships' : 'external_relationships'}}, (
    created_by_user   => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'  => {'created_by' => 'user_id'}
    },
    modified_by_user  => {
      'type'        => 'many to one',
      'class'       => 'EnsEMBL::ORM::Rose::Object::User',
      'column_map'  => {'modified_by' => 'user_id'}
    }
  );

  return $self->SUPER::setup(%params);
}

sub is_trackable {
  ## @overrides
  ## @param Optional - column/relationship object/name - if checking whether the given column/relationship is among the columns/relationships that contains trackable info
  my $self = shift;
  return (ref $_[0] ? $_[0]->name : $_[0]) =~ /^(created|modified)_(by_user|at|by)$/ ? 1 : 0 if @_;
  return 1;
}

1;
package EnsEMBL::ORM::Rose::Object::Trackable;

### NAME: EnsEMBL::ORM::Rose::Object::Trackable

### DESCRIPTION: ORM parent class for any table that contains columns 'created_by','modified_by' (both user_id foreign keys), 'created_at' and 'modified_at'
### If a class is inherited from this class, use meta_setup instead of meta->setup while object schema defination.

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object);

sub meta_setup {
  ## Wrapper around meta's setup method to automatically add trackable fields (and relationships if applicable).
  ## If object's table is not residing in the user db, methods camouflaged as relationship methods are created
  ## Use __PACKAGE__->meta_setup instead of __PACKAGE__->meta->setup to setup schema in child classes
  ## @overrides
  ## @param Same hash as for meta->setup, but with an extra flag at key 'user_db', kept on if user table is on same database as the object
  my ($class, %params) = @_;
  
  push @{$params{'columns'}}, (
    'created_by',  { type => 'integer'  },
    'created_at',  { type => 'datetime' },
    'modified_by', { type => 'integer'  },
    'modified_at', { type => 'datetime' }
  );

  # make actual relationships if same db as user table, otherwise camouflage methods as relationship method
  if (delete $params{'user_db'}) {
    push @{$params{'relationships'}}, (
      created_by_user => {
        'type'        => 'one to one',
        'class'       => 'EnsEMBL::ORM::Rose::Object::User',
        'column_map'  => {'created_by' => 'user_id'}
      },
      modified_by_user => {
        'type'        => 'one to one',
        'class'       => 'EnsEMBL::ORM::Rose::Object::User',
        'column_map'  => {'modified_by' => 'user_id'}
      }  
    );
  }
  else {
    no strict 'refs';
    foreach my $subroutine (qw(created_by_user modified_by_user)) {
      *{"${class}::$subroutine"} = sub {
        my $this    = shift;
        (my $column = $subroutine) =~ s/_user$//;
        $this->set_user($column, shift) if @_;
        return $this->get_user($column);
      };
    }
  }
  
  return $class->meta->setup(%params);
}

1;
package EnsEMBL::ORM::Rose::DataStructure;

### Name: EnsEMBL::ORM::Rose::DataStructure
### Class for column type 'datastructure' for saving a Hash or Array

### An extra boolean key 'trusted' is required (defaults to value being false) to initiate the column during AnyRoseObject->meta->setup (see &trusted below)

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::ORM::Rose::DataStructureValue;

use base qw(Rose::DB::Object::Metadata::Column::Text);

sub new {
  my $class = shift;

  my $self;

  if (ref $_[0] && UNIVERSAL::isa($_[0], 'Rose::DB::Object::Metadata::Column')) { # if trying to convert an existing column to a datastructure column
    throw exception('ORMException', 'Only text type columns can be converted to datastructure type columns') unless $_[0]->isa('Rose::DB::Object::Metadata::Column::Text');
    $self = bless $_[0], $class;
    $self->init(%{$_[1] || {}});
  } else {
    $self = $class->SUPER::new(@_);
  }

  $self->add_trigger('inflate' => sub {
    my ($object, $value) = @_;
    return $self->value_class->new($value, $self);
  });

  $self->add_trigger('deflate' => sub {
    my ($object, $value) = @_;
    $value = $self->value_class->new($value, $self) unless UNIVERSAL::isa($value, $self->value_class);
    return "$value";
  });

  return $self;
}

sub value_class {
  ## Returns the name of the class that will be instantiated to represent value of this column
  return 'EnsEMBL::ORM::Rose::DataStructureValue';
}

sub type {
  ## Returns the type of the column (polymorphic method)
  return 'datastructure';
}

sub trusted {
  ## Sets/Gets trusted flag on the column
  ## If the column value is trusted to be safely 'eval'able, keep this flag on
  ## @param Flag value
  ##  - If on, string value is 'eval'ed straight without any security validation before setting it as a value of this column (insure but faster)
  ##  - If off, value is set to this column after validation checks (secure but slower)
  my $self = shift;
  $self->{'_ens_trusted'} = shift @_ ? 1 : 0 if @_;
  return $self->{'_ens_trusted'} || 0;
}

1;

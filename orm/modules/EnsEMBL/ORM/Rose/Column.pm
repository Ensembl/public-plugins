package EnsEMBL::ORM::Rose::Column;

### NAME: EnsEMBL::ORM::Rose::Column;

### STATUS: Under development

### DESCRIPTION: A very simple object that mimics a Rose::DB::Object::MetaData::Column
### Used by DbFrontend code to populate lookups (e.g. dropdown lists) from relationships

use strict;
use warnings;
no warnings 'uninitialized';

sub new {
  my ($class, $args) = @_;
  if (!$args->{'name'}) {
    warn "!!! MUST SUPPLY NAME FOR THIS COLUMN!";
    return;
  }
  my $self = {
    '_name' => $args->{'name'},
    '_type' => $args->{'type'} || 'scalar',
    '_values' => $args->{'values'} || [],
  };
  bless $self, $class;
  return $self;
}

sub name    { return $_[0]->{'_name'}; }
sub type    { return $_[0]->{'_type'}; }
sub values  { return $_[0]->{'_values'}; }

sub is_primary_key_member { return 0; }

1;

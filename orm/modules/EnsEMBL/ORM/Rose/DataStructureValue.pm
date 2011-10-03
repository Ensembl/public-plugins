package EnsEMBL::ORM::Rose::DataStructureValue;

## Name: EnsEMBL::ORM::Rose::DataStructureValue
## Class representing the value provided to column type 'datastructure'
## Purpose of this class is to stringify the datastructure if it's being used as a string

use strict;

use Data::Dumper;
use EnsEMBL::Web::Exceptions;

use overload (
  '""'  => 'to_string',
  'cmp' => sub { my ($a, $b) = @_; return "$a" cmp "$b"; },
  'ne'  => sub { my ($a, $b) = @_; return "$a" ne  "$b"; },
  'eq'  => sub { my ($a, $b) = @_; return "$a" eq  "$b"; },
);

sub new {
  ## @constructor
  ## @param datastructure (possibly unparsed stringified)
  ## @param Rose object itself
  ## Can return a blessed hash or a blesses array depending upon the argument provided
  ## @exception ORMException::DataStructureParsingException in case problem parsing the datastructure
  my ($class, $data, $object) = @_;

  if (ref $data) {
    $data = clone($data);
  }
  else {
    my $error = '';
    $data = _parse("$data", \$error);
    throw exception('ORMException::DataStructureParsingException', $error) if $error; # if any error in parsing
  }

  $data = \"$data" unless ref $data;
  return bless $data, $class;
}

sub to_string {
  ## Stringifies the datastructure
  ## @return String
  my $self = shift;

  my $str = Data::Dumper->new([$self->isa('SCALAR') ? "$$self" : $self->clone]);
  $str->Sortkeys(1);
  $str->Indent(1);
  $str = $str->Dump;
  $str =~ s/^[^\=]+\=\s*|\;\n*$//g;
  return $str;
}

sub clone {
  ## Clones the object to hash/array accordingly
  ## Can be used as a method or a function
  my $obj = shift;

  return $obj unless ref $obj;
  return { map {clone($_)} %$obj} if UNIVERSAL::isa($obj, 'HASH');
  return [ map {clone($_)} @$obj] if UNIVERSAL::isa($obj, 'ARRAY');
}

sub _parse {
  ## @private
  ## Parses a datastructure
  ## Wraps every string with single quotes and replaces double quotes with single quotes before evaling the whole stringified datastructure
  my ($str, $error_ref) = @_;

  my $str_copy = $str;

  ## Save the offsets of all the single or double qoutes, find the strings in the datastructure and save them.
  my (@strings, @offsets, $last);
  push @offsets, [ $2, $-[2], $1 ] while $str =~ /(\\*)(\'|\")/g;

  for (@offsets) {
    if (!$last) {
      $$error_ref = "Unexpected quote found at $_->[1] in datastructure: $str_copy" and return if length($_->[2]) % 2;
      $last       = $_ and next;
    }
    next if length($_->[2]) % 2;
    if ($last->[0] eq $_->[0]) {
      my $pos     = $last->[1] + 1;
      my $substr  = substr($str, $pos, $_->[1] - $pos + 1);
      my $length  = length($substr) - 1;
      if (chop $substr eq '"') {
        $substr =~ s/\\\"/\"/g;
        $substr =~ s/\'/\\\'/g;
      }
      push @strings, [ $substr, $pos, $length ];
      $last = undef;
    }
  }

  ## If odd number of quotes
  $$error_ref = "Unbalanced quote found at index $last->[1] in the datastructure: $str_copy" and return if $last;

  ## Replace the strings temporarily with number (index from lookup)
  my $i = $#strings;
  substr($str, $_->[1] - 1, $_->[2] + 2) = sprintf q("%s"), $i-- for reverse @strings;

  ## Wrap the unquoted hash keys with single quotes
  my $str_1 = $str;
  my $str_2 = $str;
  my $i     = 0;
  while ($str_1 =~ /[\{\,]{1}[\n\s\t]*\"?([^\n\s\t\"]+)(\"?)[\n\s\t]*\=>/g) {
    next if $2;
    substr($str,   $-[1] + $i++ * 2, length $1) = qq('$1');
    substr($str_2, $-[1],            length $1) = ' ' x length $1;
  }

  ## If any unquoted string still remaining, throw exception
  while ($str_2 =~ /([a-z]+)/ig) {
    next if $1 eq 'undef';
    $$error_ref = "Unquoted string '$1' found in the datastructure: $str_copy" and return if $1;
  }

  ## all checks done, now substitute the strings back in
  $str_1   = $str;
  my $last = 0;
  while ($str_1 =~ /(\"([0-9]+)\")/g) {
    substr($str, $-[1] + $last, length $1) = qq('$strings[$2][0]');
    $last += length(qq('$strings[$2][0]')) - length $1;
  }

  # finally - safe eval
  my $data = eval "$str";

  ## if eval threw an exception
  $$error_ref = $@ and return if $@;

  return $data;
}

1;
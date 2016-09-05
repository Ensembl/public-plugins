=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::RecordManagerRose;

### Class to serve as a parent to the record manager classes that are themselves rose based objects - EnsEMBL::Web::User and EnsEMBL::Web::Group

use strict;
use warnings;

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::RecordSetRose;
use EnsEMBL::Web::Exceptions qw(WebException);

use parent qw(EnsEMBL::Web::RecordManager);

our $AUTOLOAD;

sub rose_object :Accessor;
  ## Gets the actual rose object wrapped in this web object

sub _recordset_class {
  ## @override
  ## @private
  return 'EnsEMBL::Web::RecordSetRose';
}

sub can {
  ## @overrides UNIVERSAL's can
  my ($self, $method) = @_;

  my $coderef = $self->SUPER::can($method);

  return $coderef if $coderef;

  my $rose_object = $self->rose_object;

  return unless $rose_object && $rose_object->can($method);

  return sub {
    my $self = shift;
    return $self->rose_object->can($method)->($self->rose_object, @_);
  }
}

sub AUTOLOAD {
  ## Falls back to calling the corresponding method for the linked rose object
  my $self    = shift;
  my $method  = $AUTOLOAD =~ s/.*:://r;
  my $coderef = $self->can($method);

  throw WebException(sprintf 'Could not call method "%s" on "%s" since no Rose::DB::Object is linked to this object', $method, ref $self) unless $coderef;

  return $coderef->($self, @_);
}

## Methods to fetch specific records
sub bookmarks     :Deprecated('use records') { shift->records('bookmark');     }
sub histories     :Deprecated('use records') { shift->records('history');      }
sub specieslists  :Deprecated('use records') { shift->records('specieslist');  }

1;

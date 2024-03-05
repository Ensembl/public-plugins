=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Exception::HiveException;

### Exception class to be used in the Hive RunnableDB scripts
### If an error occurs in hive, it saves the error string to its database. Thus this class returns JSON string as an error string which is further used by the web server to handle those errors.

use strict;
use warnings;

use JSON qw(to_json from_json);

use parent qw(EnsEMBL::Web::Exception);

sub to_string {
  ## @overrides
  ## Converts the Exception object into a JSON string
  return to_json(shift->_to_hash);
}

sub handle {
  ## @static
  ## Handles the exception
  ## @param Exception JSON string
  ## @param Subroutine to be called to handle this exception
  ## @params List of extra arguments for the given subroutine
  my ($exception, $sub) = splice @_, 0, 2;
  return $sub->(_to_hash($exception), @_);
}

sub _to_hash {
  ## @private
  ## Converts an exception object (or it's JSON representation) to a simple hash
  my $self = shift;
  if (ref $self) {
    return {
      'class' => ref $self,
      map {( substr($_, 1),  $self->{$_})} keys %$self
    };
  } else { # converting from JSON string
    return from_json($self);
  }
}

1;

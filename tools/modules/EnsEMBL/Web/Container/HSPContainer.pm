=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Container::HSPContainer;

### Wrapper around ORM::EnsEMBL::DB::Tools::Object::Result and provides method for compatibility with drawing code
### TODO - removed non-container stuff from this!

use strict;
use warnings;

sub new {
  ## @constructor
  ## @param Blast web object
  ## @param Job object
  ## @param Colours map for the pointers
  my ($class, $object, $job, $colours) = @_;

  my $sequence  = $object->get_input_sequence_for_job($job);
  my $results   = $job->result;

  return bless {
    'name'    => $sequence->{'display_id'},
    'length'  => CORE::length($sequence->{'sequence'}),
    'hsps'    => [ map {
      my $hsp       = $_->result_data->raw;
      $hsp->{'id'}  = $_->result_id;
      $hsp->{'tl'}  = $object->create_url_param({'result_id' => $hsp->{'id'}});
      $hsp;
    } @$results ],
    'colours' => $colours
  }, $class;
}

sub start   { return 0;                   }
sub end     { return shift->{'length'};   }
sub length  { return shift->{'length'};   }
sub hsps    { return shift->{'hsps'};     }
sub colours { return shift->{'colours'};  }
sub name    { return shift->{'name'};     }

1;

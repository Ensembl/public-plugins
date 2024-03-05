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

package EnsEMBL::Users::Command::Account::Favourites::Save;

use strict;
use warnings;

use JSON;
use List::MoreUtils qw(uniq);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $fav   = join ',', uniq split ',', $hub->param('favourites') || ''; # 'uniq' preserves order too
  my $args  = {'type' => 'specieslist', 'code' => 'specieslist'};

  if ($fav) {
    $args->{'favourites'} = $fav;
    $user->set_record_data($args);
  } else {
    $user->delete_records($args);
  }

  print to_json({'updated' => 1});
}

1;

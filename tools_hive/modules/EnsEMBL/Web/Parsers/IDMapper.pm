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

package EnsEMBL::Web::Parsers::IDMapper;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Parsers);

sub parse {
  my ($self, $file) = @_;

  my %rows;

  for ( map  { 'old' => $_->[0] =~ s/\.[0-9]+$//r, 'new' => $_->[1], 'release' => $_->[2] },  # create a hash for each filtered row
        grep { $_->[0] && $_->[0] ne 'Old stable ID' && $_->[1] && $_->[2] !~ /\D/ }          # exclude headers and rows with retired ids
        file_get_contents($file, sub { return [ map s/^\s+|\s+$//gr, split ',', $_ ]; })      # parse each row of CVS into an array
  ) {
    $rows{$_->{'old'}}{'id'} = $_->{'old'};
    push @{$rows{$_->{'old'}}{'mappings'}}, [ $_->{'release'}, $_->{'new'} ];
  }

  return [ values %rows ];
}

1;

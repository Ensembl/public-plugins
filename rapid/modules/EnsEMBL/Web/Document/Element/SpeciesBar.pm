=head1 LICENSE

Copyright [2009-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::SpeciesBar;

sub species_list {
  my $self      = shift;
  my $total     = scalar @{$self->{'species_list'}};
  my ($all_species, $fav_species);
  
  if ($self->{'favourite_species'}) {
    $fav_species .= qq{<li><a class="constant" href="$_->[0]">$_->[1]</a></li>} for @{$self->{'favourite_species'}};
    $fav_species  = qq{<h4>Favourite species</h4><ul>$fav_species</ul><div style="clear: both;padding:1px 0;background:none"></div>};
  }
  
  for my $i (0..$total-1) {
      $all_species .= sprintf '<li>%s</li>', $self->{'species_list'}[$i] ? qq{<a class="constant" href="$self->{'species_list'}[$i][0]">$self->{'species_list'}[$i][1]</a>} : '&nbsp;';
  }

  return sprintf '<div class="dropdown species">%s<h4>%s</h4><ul>%s</ul></div>', $fav_species, $fav_species ? 'All species' : 'Select a species', $all_species;  
}

1;

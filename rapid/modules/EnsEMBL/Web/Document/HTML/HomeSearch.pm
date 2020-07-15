=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::HomeSearch;


sub munge_species {
  my $self = shift;
  my $hub = $self->hub;

  my $species_info = $hub->get_species_info;
  my %species;

  while (my($k, $v) = each (%$species_info)) {
    my $name = $species_info->{$k}{'scientific'};
    if ($species_info->{$k}{'strain'} && $species_info->{$k}{'strain'} !~ /reference/) {
      $name .= sprintf ' (%s)', $species_info->{$k}{'strain'};
    }
    $species{$name} = $k;
  }

  return %species;
}

1;


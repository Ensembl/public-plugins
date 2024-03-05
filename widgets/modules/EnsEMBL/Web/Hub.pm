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

package EnsEMBL::Web::Hub;

use strict;
use warnings;

use EnsEMBL::Web::Tools::FailOver::GXA;
use EnsEMBL::Web::Tools::FailOver::Pathway;

# check to see if GXA is site is up or down
# if $out that means site is up
sub gxa_status {

  my $self = shift;

  my $failover = EnsEMBL::Web::Tools::FailOver::GXA->new($self);
  my $out      = $failover->get_cached;

  return $out;
}

# check to see if PlantReactome is site is up or down
# if $out that means site is up
sub pathway_status {

  my $self = shift;

  my $failover = EnsEMBL::Web::Tools::FailOver::Pathway->new($self);
  my $out      = $failover->get_cached;
  return $out;
}

1;


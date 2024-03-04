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

package EnsEMBL::Web::Apache::SpeciesHandler;

use strict;
use warnings;

use EnsEMBL::Web::Tools::FailOver::ToolsDB;

use previous qw(get_controller);

sub get_controller {
  ## @plugin
  ## Change the controller for Tools pages to ToolsFailure in case Tools db is down
  my ($species, $path_segments, $query) = @_;

  my $controller = PREV::get_controller(@_);

  if ($path_segments->[0] && $path_segments->[0] eq 'Tools' && (-e $SiteDefs::TOOLS_UNAVAILABLE_MESSAGE_FILE || !EnsEMBL::Web::Tools::FailOver::ToolsDB->new->get_cached)) {
    return $controller =~ s/::(\w+)$/::ToolsFailure::$1/r;
  }

  return $controller;
}

1;

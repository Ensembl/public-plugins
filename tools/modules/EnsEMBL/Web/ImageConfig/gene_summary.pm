=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfig::gene_summary;

### Plugin to core EnsEMBL::Web::ImageConfig::gene_summary to add blast result tracks to the image

use strict;
use warnings;

sub init_non_cacheable {
  ## Adds blast track to the config
  my $self = shift;
  $self->SUPER::init_non_cacheable(@_);
  $self->initialize_tools_tracks;
}

1;

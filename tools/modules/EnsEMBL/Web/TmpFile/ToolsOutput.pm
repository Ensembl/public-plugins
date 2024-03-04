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

package EnsEMBL::Web::TmpFile::ToolsOutput;

use strict;

use parent 'EnsEMBL::Web::TmpFile';

sub fix_filename {
  ## @override
  ## We always have full absolute path, so no need to fix it
  my ($self, $filename) = @_;

  $self->{'full_path'} = $filename;

  return $self->{'filename'};
}

1;

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Tools::JavascriptOrderWidgets;

use strict;

use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);

sub new {
  return  bless { 'dir' => [ split 'modules', __FILE__ ]->[0] . 'htdocs' }, shift;
}

sub get_files {
  my ($self, $absolute) = @_;
   
  return map { ($absolute ? $self->{'dir'} : '') . "/widgets/$_" } sort @{list_dir_contents($self->{'dir'}.'/widgets')};
}

1;

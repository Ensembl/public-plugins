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

package EnsEMBL::Web::Component::UserData;

use base qw(EnsEMBL::Web::Component);

use strict;

sub add_extra_formats {
  my ($self, $format_info) = @_;

  ## For the VEP upload, only one format is valid
  if ($self->hub->param('tool') && $self->hub->param('tool') eq 'VEP') {
    $format_info = {'gene_list' => {
                                    'ext' => 'txt',
                                    'label' => 'Gene or feature list',
                                    'display' => 'feature',
                                    }
                    };
  }
  return $format_info;
}

1;

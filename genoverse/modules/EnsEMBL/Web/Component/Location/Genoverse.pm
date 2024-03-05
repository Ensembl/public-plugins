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

package EnsEMBL::Web::Component::Location::Genoverse;

## Panel to display genoverse image
## This panel only gets loaded if it's confirmed that we need a genoverse image

use strict;
use warnings;

use EnsEMBL::Web::Document::Image::Genoverse;

use parent qw(EnsEMBL::Web::Component::Location);

sub _init {
  my $self = shift;
  $self->ajaxable(1);
  $self->configurable(1);
  $self->has_image(1);
}

sub content {
  my $self  = shift;
  my $slice = shift || $self->object->slice;
  my $hub   = $self->hub;
  my $image = $self->new_image($slice, $hub->get_imageconfig($self->view_config->image_config_type));

  return $image->render;
}

sub new_image {
  my ($self, $slice, $image_config) = @_;

  return EnsEMBL::Web::Document::Image::Genoverse->new($self->hub, $self, {
    slice        => $slice,
    export       => 1,
    image_config => $image_config,
    image_width  => $self->image_width,
  });
}

1;

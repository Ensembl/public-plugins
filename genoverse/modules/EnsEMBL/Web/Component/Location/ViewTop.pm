=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Location::ViewTop;

use strict;
use warnings;

use previous qw(content);

use EnsEMBL::Web::Component::Location::Genoverse;

sub new {
  ## @override
  ## Returns the self object blessed with Genoverse class if its confirmed that we need a Genoverse image
  my $self  = shift->SUPER::new(@_);
  my $hub   = $self->hub;

  # if genoverse request is confirmed, re-bless the object
  if (!$self->force_static && $hub->param('genoverse')) {
    $self = bless $self, 'EnsEMBL::Web::Component::Location::Genoverse';
    $self->_init;
  }

  return $self;
}

sub force_static {
  ## Confirms if the image needed is static ViewTop
  ## @return Boolean
  my $self  = shift;
  my $hub   = $self->hub;

  return $self->{'_force_static'} //= ($hub->session->get_record_data({type => 'image_type', code => $self->id}))->{'static'} || $hub->param('export') || 0;
}

sub content {
  ## @override
  ## Returns the default ViewTop panel if it's confirmed that we need a static image, otherwise return JS panel to check if the browser supports Genoverse
  ## This method does NOT get called if it's decided that we need a genoverse image
  my $self = shift;

  return $self->force_static ? $self->PREV::content(@_) : q(<div class="js_panel"><input type="hidden" class="panel_type" value="GenoverseTest" /></div>);
}

1;

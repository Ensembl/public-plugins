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

package EnsEMBL::Web::Document::Element::ToolButtons;

use strict;
use warnings;

use previous qw(init);

sub init {
  my $self        = shift;
  my $controller  = shift;
  my $hub         = $self->hub;
  my $title       = $controller->page->title;

  my $url         = $hub->url({
    'type'          => 'Account',
    'action'        => 'Bookmark/Add',
    '__clear'       => 1,
    'name'          => $title->get_short,
    'description'   => $title->get,
    'url'           => $hub->species_defs->ENSEMBL_BASE_URL . $hub->current_url
  });

  if (!$hub->user) {
    $url = $hub->url({
      'type'    => 'Account',
      'action'  => 'Login',
      'then'    => $url
    });
  }

  $self->PREV::init($controller, @_);

  $self->add_entry({
    caption => 'Bookmark this page',
    icon    => 'bookmark',
    class   => 'modal_link',
    url     => $url
  });
}

1;

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

package EnsEMBL::Web::Document::Element::ToolButtons;

use strict;
use warnings;

use previous qw(label_classes init _has_data);

use URI::Escape qw(uri_escape);

sub label_classes {
  my $classes = shift->PREV::label_classes(@_);

  $classes->{'Bookmark this page'} = 'bookmark';

  return $classes;
}

sub init {
  my $self        = shift;
  my $controller  = shift;
  my $hub         = $self->hub;
  my $title       = $controller->page->title;

  my $url         = $hub->url({
    'type'          => 'Account',
    'action'        => 'Bookmark/Add',
    '__clear'       => 1,
    'name'          => uri_escape($title->get_short),
    'description'   => uri_escape($title->get),
    'url'           => uri_escape($hub->species_defs->ENSEMBL_BASE_URL . $hub->current_url)
  });

  if (!$hub->user) {
    $url = $hub->url({
      'type'    => 'Account',
      'action'  => 'Login',
      'then'    => uri_escape($url)
    });
  }

  $self->PREV::init($controller, @_);

  $self->add_entry({
    caption => 'Bookmark this page',
    class   => 'modal_link',
    url     => $url
  });
}

sub _has_data {
  my $self = shift;

  return 1 if $self->PREV::_has_data;

  my $hub  = $self->hub;
  my $user = $hub->user;

  return !!($user && (grep $user->get_records($_), qw(uploads urls dases)))
}

1;

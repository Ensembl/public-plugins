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

package EnsEMBL::Web::Document::Element::Tabs;

# Adds Tools tab to the existing tabs

use strict;
use warnings;

use previous qw(init dropdown);

sub init {
  my $self        = shift;
  my $controller  = $_[0];
  my $hub         = $controller->hub;
  my $user        = $hub->user;

  $self->PREV::init(@_);

  my $entries = $self->entries;

  # if tools tab is already there (because of the tl param or because hub type is Tools), force a dropdown add required classes
  if (my ($tab) = grep {($_->{'type'} || '') eq 'Tools'} @$entries) {
    $tab->{'dropdown'}  = 'tools';
    $tab->{'class'}    .= ' hidden'.($hub->type eq 'Tools' ? ' final' : '');

  } else {

    # Add a tools tab, but keep it hidden. A future ajax request will decide its fate.
    $self->add_entry({
      'type'      => 'Tools',
      'caption'   => 'Jobs',
      'url'       => $hub->url({qw(type Tools action Summary __clear 1)}),
      'class'     => 'tools hidden',
      'dropdown'  => 'tools'
    });
  }
}

1;

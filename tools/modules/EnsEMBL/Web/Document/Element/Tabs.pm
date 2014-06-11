=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use previous qw(init);

use ORM::EnsEMBL::DB::Tools::Manager::Ticket;

sub init {
  my $self        = shift;
  my $controller  = $_[0];
  my $hub         = $controller->hub;
  my $user        = $hub->user;

  $self->PREV::init(@_);

  if (!$controller->builder->object('Tools') && ORM::EnsEMBL::DB::Tools::Manager::Ticket->count_current_tickets({
    'site_type'   => $hub->species_defs->ENSEMBL_SITETYPE,
    'session_id'  => $hub->session->create_session_id, $user ? (
    'user_id'     => $user->user_id ) : ()
  })) {

    my $tl_param  = $hub->param('tl');
       $tl_param  = $tl_param ? {'tl' => $tl_param} : {};

    $self->add_entry({
      'type'    => 'Tools',
      'caption' => 'Jobs', # TODO - change for 76
      'url'     => $hub->url({qw(type Tools action VEP), %$tl_param}), # TODO - change VEP to Summary for 76
      'class'   => 'tools '.($hub->type eq 'Tools' ? ' active' : '')
    });
  }
}

1;

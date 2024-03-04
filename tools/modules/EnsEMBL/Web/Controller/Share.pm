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

package EnsEMBL::Web::Controller::Share;

use strict;
use warnings;

use previous qw(share_create);

sub share_create {
  ## @plugin
  ## Change ticket visibility to 'public' before sharing Tools/Result url
  my $self  = shift;
  my $hub   = $self->hub;
  my $ref   = $hub->referer;

  if ($hub->tools_available && ($ref->{'ENSEMBL_TYPE'} || '') eq 'Tools' && $ref->{'ENSEMBL_ACTION'} && ($ref->{'ENSEMBL_FUNCTION'} || '') eq 'Results') {

    if (my $object = $self->new_object($ref->{'ENSEMBL_ACTION'}, {}, { _hub => $hub })) {

      $hub->param('tl', @{$ref->{'params'}{'tl'} || []}); # get_requested_ticket only looks at current url param

      # share link will only work if visibility is public
      $object->change_ticket_visibility('public') if $object->get_requested_ticket;
    }
  }

  return $self->PREV::share_create(@_);
}

1;

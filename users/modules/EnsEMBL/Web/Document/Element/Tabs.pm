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

### Plugin file to add history dropdown to tabs for the logged-in user

use strict;
use warnings;

use previous qw(new);

sub new {
  my $self = shift->PREV::new(@_);
  $self->{'history'}    = {};
  $self->{'bookmarks'}  = {};
  return $self;
}

sub init_history {
  my ($self, $hub) = @_;
  my $user         = $hub->user;
  my $species_defs = $hub->species_defs;
  my $type         = $hub->type;
  my $species      = $hub->species;
  my $servername   = $species_defs->ENSEMBL_SERVERNAME;
  my $entries      = $self->entries;

  # set only required keys for history and bookmarks
  my %history      = map { $_->{'dropdown'} ? ($_->{'type'} => []) : () } @$entries;
  my %bookmarks    = map { $_ => [] } keys %history;

  for (@{$user->histories}) {
    my $object = $_->object;
    push @{$history{$object}}, $_ if $object && $history{$object} && $_->url =~ /$servername/;
  }

  for (@{$user->bookmarks}) {
    my $object = $_->object;
    push @{$bookmarks{$object}}, $_ if $object && $bookmarks{$object} && $_->url =~ /\/$object\// && $_->url =~ /$servername/;
  }

  foreach my $t (keys %history) {
    foreach (@{$history{$t}}) {
      my %clear = $_->species eq $species ? () : ( __clear => 1 );
      unshift @{$self->{'history'}{lc $t}}, [ $type eq $t ? $hub->url({ species => $_->species, $_->param => $_->value, %clear }) : $_->url, $_->name ];
    }

    push @{$self->{'history'}{lc $t}}, [ $hub->url({'type' => 'Account', 'action' => 'ClearHistory', 'object' => $t }), 'Clear history', ' clear_history bold' ] if scalar @{$history{$t}};
  }

  foreach my $t (keys %bookmarks) {
    my $i;
    foreach (sort { $b->click <=> $a->click || $b->modified_at cmp $a->modified_at } @{$bookmarks{$t}}) {
      push @{$self->{'bookmarks'}{lc $t}}, [ $hub->url({'type' => 'Account', 'action' => 'Bookmark', 'function' => 'Use', 'id' => $_->record_id}), $_->name, $_->record_id ];
      last if ++$i == 5;
    }
    push @{$self->{'bookmarks'}{lc $t}}, [ $hub->url({qw(type Account action Bookmark function View)}), 'More...',  ' modal_link bold' ] if scalar @{$bookmarks{$t}} > 5;
  }
}

1;

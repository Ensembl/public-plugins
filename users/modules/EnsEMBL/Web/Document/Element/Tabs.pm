package EnsEMBL::Web::Document::Element::Tabs;

### Plugin file to add history dropdown to tabs for the logged-in user

use strict;

use EnsEMBL::Web::Tools::MethodMaker ('copy' => {'new' => '_new'});

sub new {
  my $self = shift->_new(@_);
  $self->{'history'}    = {};
  $self->{'bookmarks'}  = {};
  return $self;
}

sub init_history {
  my ($self, $hub, $builder) = @_;
  my $user         = $hub->user;
  my $species_defs = $hub->species_defs;
  my $type         = $hub->type;
  my $species      = $hub->species;
  my $servername   = $species_defs->ENSEMBL_SERVERNAME;
  my (%history, %bookmarks);

  for (@{$user->histories}) {
    my $object = $_->object;
    push @{$history{$object}}, $_ if $object && $builder->object($object) && $_->url =~ /$servername/;
  }

  for (@{$user->bookmarks}) {
    my $object = $_->object;
    push @{$bookmarks{$object}}, $_ if $object && $_->url =~ /\/$object\// && $builder->object($object) && $_->url =~ /$servername/;
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

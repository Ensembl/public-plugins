package EnsEMBL::Web::Document::Element::Tabs;

# Adds Tools tab to the existing tabs

use strict;
use warnings;

use previous qw(init);

sub init {
  my $self        = shift;
  my $controller  = $_[0];
  my $hub         = $controller->hub;

  $self->PREV::init(@_);

  unless ($controller->builder->object('Tools')) {
    $self->add_entry({
      type    => 'Tools',
      action  => 'Blast',
      caption => 'Tools',
      url     => $hub->url({qw(type Tools action Blast)}),
      class   => 'tools '.($hub->type eq 'Blast' ? ' active' : '')
    });
  }
}

1;

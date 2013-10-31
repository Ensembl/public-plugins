package EnsEMBL::Web::Document::Element::Tabs;

# Adds Tools tab to the existing tabs

use strict;
use warnings;

use previous qw(init);

sub init {
  my $self        = shift;
  my $controller  = $_[0];
  my $hub         = $controller->hub;
  my $tl_param    = $hub->param('tl');
     $tl_param    = $tl_param ? {'tl' => $tl_param} : {};

  $self->PREV::init(@_);

  unless ($controller->builder->object('Tools')) {
    $self->add_entry({
      type    => 'Tools',
      caption => 'Tools',
      url     => $hub->url({qw(type Tools action Summary), %$tl_param}),
      class   => 'tools '.($hub->type eq 'Tools' ? ' active' : '')
    });
  }
}

1;

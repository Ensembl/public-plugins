package EnsEMBL::Web::Controller;

use strict;

use Apache2::RequestUtil;
use CGI;

sub new {
  my $class = shift;
  my $r     = shift || Apache2::RequestUtil->can('request') ? Apache2::RequestUtil->request : undef;
  my $args  = shift || {};
  my $input = new CGI;

  my $object_params = [
    [ 'Phenotype',           'ph'  ],
    [ 'Location',            'r'   ],
    [ 'Gene',                'g'   ],
    [ 'Transcript',          't'   ],
    [ 'Variation',           'v'   ],
    [ 'StructuralVariation', 'sv'  ],
    [ 'Regulation',          'rf'  ],
    [ 'Experiment',          'ex'  ],
    [ 'Marker',              'm'   ],
    [ 'LRG',                 'lrg' ],
    [ 'GeneTree',            'gt'  ],
    [ 'Tools',               'tk'  ], 
  ];

  my $object_types    = { map { $_->[0] => $_->[1] } @$object_params };
  my $ordered_objects = [ map $_->[0], @$object_params ];

  my $hub = new EnsEMBL::Web::Hub({
    apache_handle  => $r,
    input          => $input,
    object_types   => $object_types,
    session_cookie => $args->{'session_cookie'},
    user_cookie    => $args->{'user_cookie'},
  });

  my $builder = new EnsEMBL::Web::Builder({
    hub             => $hub,
    object_params   => $object_params,
    object_types    => $object_types,
    ordered_objects => $ordered_objects
  });

  my $self = {
    r             => $r,
    input         => $input,
    hub           => $hub,
    builder       => $builder,
    cache         => $hub->cache,
    type          => $hub->type,
    action        => $hub->action,
    function      => $hub->function,
    command       => undef,
    filters       => undef,
    errors        => [],
    page_type     => 'Dynamic',
    renderer_type => 'String',
    %$args
  };

  bless $self, $class;

  my $species_defs = $hub->species_defs;

  $CGI::POST_MAX = $species_defs->CGI_POST_MAX; # Set max upload size

  if ($self->cache && $self->request ne 'modal') {
    # Add parameters useful for caching functions
    $self->{'session_id'}  = $hub->session->session_id;
    $self->{'user_id'}     = $hub->user;
    $self->{'url_tag'}     = $hub->url({ update_panel => undef }, undef, 1);
    $self->{'cache_debug'} = $species_defs->ENSEMBL_DEBUG_FLAGS & $species_defs->ENSEMBL_DEBUG_MEMCACHED;

    $self->set_cache_params;
  }

  $self->init;

  return $self;
}

1;

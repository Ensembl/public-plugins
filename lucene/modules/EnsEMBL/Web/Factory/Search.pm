package EnsEMBL::Web::Factory::Search;

use strict;

use base qw(EnsEMBL::Web::Factory);
use EnsEMBL::Web::Cache;

sub createObjects {
    my $self = shift;

    ### Parse parameters to get Species names
    my @species = $self->param('species') || $self->species;
    #( my $SPECIES = $self->species ) =~ s/_/ /g;
    if (@species) {
        $self->param( 'species', @species );
    }

    ### Set up some extra variables in the new object 
    my $data = $self->__data;
    $data->{'__status'} = 'no_search';
    $data->{'__error'}  = undef;

    ### Create Lucene domain object
    my $lucene = eval { Lucene::WebServiceWrapper->new({
          'endpoint'      => $self->species_defs->LUCENE_ENDPOINT,
          'ext_endpoint'  => $self->species_defs->LUCENE_EXT_ENDPOINT,
    })};
    if ($@) {
        warn "!!! Failed to connect to Lucene Search engine: $@";
        $data->{'__status'} = ('failure');
        $data->{'__error'} = ("Search engine failure: $@");
    }

    ## Make this into an EnsEMBL::Web::Object
    my $object = $self->new_object('Search', $lucene, $data);
    $object->parse;
    if ( $object->__error || $object->__status eq 'failure' ) {
      $self->problem( 'fatal', 'Search Engine Error', 'Search is currently unavailable' );
      warn '!!!  SEARCH FAILURE: ' . $object->__error;
    }
    $self->DataObjects($object);
}

1;

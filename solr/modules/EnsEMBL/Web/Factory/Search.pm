package EnsEMBL::Web::Factory::Search;

use strict;

use base qw(EnsEMBL::Web::Factory);
use EnsEMBL::Web::Cache;

sub createObjects {
    my $self = shift;

    # Create object here
    my $endpoint = $self->species_defs->ENSEMBL_SOLR_ENDPOINT;
    my $solr = {
      endpoint => $endpoint
    };

    my $object = $self->new_object('Search', $solr, $self->__data);
    $self->DataObjects($object);
}

1;

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

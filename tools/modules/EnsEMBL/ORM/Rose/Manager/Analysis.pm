package EnsEMBL::ORM::Rose::Manager::Analysis;

### NAME: EnsEMBL::ORM::Rose::Manager::Analysis
### Module to handle multiple Analysis entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Analysis objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Analysis' }

## Auto-generate query methods: get_tickets, count_tickets, etc
__PACKAGE__->make_manager_methods('analysis');

#Data mining_methods 

sub retrieve_analysis_object {
  my ($self, $ticket_id) = @_;
  return undef unless $ticket_id;

  my $analysis = $self->get_analysis(
    query => ['ticket_id' => $ticket_id]
  );

  my $object = $analysis->[0]->object;
  return $object;
}

1;



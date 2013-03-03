package EnsEMBL::ORM::Rose::Manager::SubJob;

### NAME: EnsEMBL::ORM::Rose::Manager::SubJob
### Module to handle multiple SubJob entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::SubJob objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::SubJob' }

## Auto-generate query methods: get_sub_jobs, count_sub_jobs, etc
__PACKAGE__->make_manager_methods('sub_jobs');


#Data mining methods 

sub fetch_by_id {
  my ($self, $id) = @_;
  my $sub_job = $self->get_sub_jobs(
    query => ['sub_job_id' => $id]
  );

  return $sub_job->[0];
}

1;


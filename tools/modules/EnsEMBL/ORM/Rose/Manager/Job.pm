package EnsEMBL::ORM::Rose::Manager::Job;

### NAME: EnsEMBL::ORM::Rose::Manager::Job
### Module to handle multiple Job entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Job objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Job' }

## Auto-generate query methods: get_jobs, count_jobs, etc
__PACKAGE__->make_manager_methods('jobs');

# Data Minimg methods
sub get_job_id_by_name {
  my ($self, $name) = @_;
  return undef unless $name;

  my $jobs = $self->get_jobs(
    query => [job_type => $name]
  );

  return $jobs->[0]->job_type_id;
}

1;


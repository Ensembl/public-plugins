package EnsEMBL::Web::Component::Tools::VEP;

### Base class for all Blast components

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Web::Component::Tools);

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Extra param hashref as required by expand_job_status method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $params) = @_;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Description',    $job->job_desc // '-');
  $two_col->add_row('Status',         $self->expand_job_status($job, $params)->render);

  return $two_col;
}

1;

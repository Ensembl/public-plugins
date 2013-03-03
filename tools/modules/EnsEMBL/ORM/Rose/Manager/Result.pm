package EnsEMBL::ORM::Rose::Manager::Result;

### NAME: EnsEMBL::ORM::Rose::Manager::Result
### Module to handle multiple HiveJob entries 

### STATUS: Under Development

### DESCRIPTION:
### Enables fetching, counting, etc., of multiple Rose::Object::Result objects

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Manager);

sub object_class { 'EnsEMBL::ORM::Rose::Object::Result' }

## Auto-generate query methods: get_results, count_results, etc
__PACKAGE__->make_manager_methods('results');


# Data-mining methods 
sub fetch_results_by_ticket_sub_job {
  my ($self, $ticket_id, $sub_job_id) = @_;
  my $results = $self->get_results(
    query => ['ticket_id' => $ticket_id, 'sub_job_id' => $sub_job_id]
  );
  return $results;
}


sub fetch_result_by_result_id {
  my ($self, $result_id) = @_;
  return undef unless $result_id;
  
  my $result = $self->get_results(
    with_objects => ['sub_job'],
    query => ['result_id' => $result_id]
  );
   
  return $result;
}

sub fetch_all_results_in_region {
  my ($self, $ticket_id, $slice) = @_;
  my $sr_name = $slice->seq_region_name;
  my $sr_start = $slice->start;
  my $sr_end  = $slice->end;

  # First select where complete result is within region  
  my $results1 = $self->get_results(
    query => ['ticket_id' => $ticket_id,
              'chr_name'  => $sr_name,
              'chr_start' => { ge => $sr_start},
              'chr_end'   => { le => $sr_end}   
          ]
  ); 

  # Next select where end of result is within region
    my $results2 = $self->get_results(
    query => ['ticket_id' => $ticket_id,
              'chr_name'  => $sr_name,
              'chr_start' => { lt => $sr_start}, 
              'chr_end'   => { le => $sr_end},
              'chr_end'   => { gt => $sr_start}
          ]
  );        

  # Next select where start of result is within region
  my $results3 = $self->get_results(
  query => ['ticket_id' => $ticket_id,
            'chr_name'  => $sr_name,
            'chr_start' => { ge => $sr_start}, 
            'chr_start' => { le => $sr_end},
            'chr_end'   => { gt => $sr_end},
          ]
  ); 

  # Next select where result spans entire region
  my $results4 = $self->get_results(
  query => ['ticket_id' => $ticket_id,
            'chr_name'  => $sr_name,
            'chr_start' => { lt => $sr_start}, 
            'chr_end'   => { gt => $sr_end},
            'chr_start' => { lt => $sr_end},
          ]
  );

  my @results = ( @{$results1}, @{$results2}, @{$results3}, @{$results4});
  
  return \@results;
}

1;


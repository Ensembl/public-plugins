package EnsEMBL::Web::Container::HSPContainer;

### Wrapper around ORM::EnsEMBL::DB::Tools::Object::Result and provides method for compatibility with drawing code

use strict;
use warnings;

sub new {
  ## @constructor
  ## @param Job object
  ## @param Colours map for the pointers
  my ($class, $job, $colours) = @_;

  my $job_data  = $job->job_data;
  my $results   = $job->result;

  return bless {
    'name'    => $job_data->{'sequence'}{'display_id'},
    'length'  => CORE::length($job_data->{'sequence'}{'seq'}),
    'hsps'    => [ map { my $hsp = $_->result_data; $hsp->{'id'} = $_->result_id; $hsp; } @$results ],
    'colours' => $colours
  }, $class;
}

sub start   { return 0;                   }
sub end     { return shift->{'length'};   }
sub length  { return shift->{'length'};   }
sub hsps    { return shift->{'hsps'};     }
sub colours { return shift->{'colours'};  }
sub name    { return shift->{'name'};     }

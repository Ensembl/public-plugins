=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JobDispatcher;

### Abstract parent class for all job dispatchers

use strict;
use warnings;

use EnsEMBL::Web::Attributes;

sub hub { return shift->{'_hub'}; }

sub new {
  ## @constructor
  my ($class, $hub) = @_;
  return bless {'_hub' => $hub}, $class;
}

sub dispatch_job :Abstract {
  ## @abstract
  ## Sends the jobs to the external (or internal) job processor, eg. hive or web services
  ## @param Ticket type name (string)
  ## @param Hashref of the job data to be dispatched
  ## @return ID/reference to be used to retrieve the submitted job in future
}

sub delete_jobs :Abstract {
  ## @abstract
  ## Deletes the submitted jobs
  ## @param Ticket type name (string)
  ## @param Arrayref of Id/References for the submitted jobs to be removed
}

sub update_jobs :Abstract {
  ## @abstract
  ## Updates the tools job objects according to the recent status in dispatcher
  ## @param Arrayref of tools job objects to be updated
}

sub default_error_message {
  ## Default message to be displayed if the job has failed
  return 'An error occurred while running the job.';
}

1;

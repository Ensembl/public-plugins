=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Ticket;

use strict;
use warnings;

use previous qw(handle_exception);

sub handle_exception {
  my ($self, $exception, $stage) = @_;

  # is it a HiveError and do we have a better message to display for that?
  if ($exception->type eq 'HiveError' && (my $message = $self->hub->species_defs->ENSEMBL_HIVE_ERROR_MESSAGE)) {
    warn $exception->message(1);

    try {

      # add message to each job
      foreach my $job (@{$self->jobs}) {
        $job->rose_object->job_message([{
          'display_message' => $message,
          'exception'       => {'exception' => $exception->message(1)},
          'fatal'           => 0
        }]);
        $job->save;
      }

    } catch {};

    $self->{'_error'} = {
      'heading' => 'Service unavailable',
      'stage'   => $stage,
      'message' => $message
    };
  } else {
    $self->PREV::handle_exception($exception, $stage);
  }
}

1;

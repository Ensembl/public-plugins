=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::RunnableDB;

### Parent class for all the runnabledb classes for different tools
### The child modules of this class are not used by the webserver directly, but are used by hive to actually run the bsubed jobs.
### Error handling: In any child classes, "throw exception('HiveException', 'message ..')" to passes them back to the web server

use strict;
use warnings;

use base qw(Bio::EnsEMBL::Hive::Process);

use Storable qw(nfreeze);
use IO::Compress::Gzip qw(gzip $GzipError);

use EnsEMBL::Web::Exceptions;

sub param_required {
  ## @overrides
  ## Throws a HiveException in case a param is not defined and is required
  my ($self, $param_name) = @_;

  throw exception('HiveException', "Param '$param_name' is not defined.") unless $self->param_is_defined($param_name);

  return $self->param($param_name);
}

sub save_results {
  ## Writes the results to the result table of ticket db
  ## Use this in 'write_output' to save results
  ## @param Job id to write results against
  ## @param Arrayref of hashrefs (each hashref goes in result_data column)
  my ($self, $job_id, $results) = @_;

  if (@$results) {

    # Serialise and compress results to save them to db
    my @serialised_results = map {
      my $serialised = nfreeze($_);
      my $serialised_gzip;
      gzip(\$serialised => \$serialised_gzip, -LEVEL => 9) or throw exception('HiveException', "GZIP failed: $GzipError");
      $serialised_gzip;
    } @$results;

    my $ticket_db   = $self->param('ticket_db');
    my $ticket_dbh  = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $ticket_db->{'-dbname'}, $ticket_db->{'-host'}, $ticket_db->{'-port'}), $ticket_db->{'-user'}, $ticket_db->{'-pass'}, { 'PrintError' => 0 });

    if ($ticket_dbh) {
      my $now = $self->_get_time_now;
      my $sth = $ticket_dbh->prepare('INSERT INTO `result` (`job_id`, `result_data`, `created_at`) values ' . join(',', map {'(?,?,?)'} @serialised_results));

      $sth->execute(map {($job_id, $_ || '', $now)} @serialised_results);

    } else {

      ## TODO -- what if ticket connection comes back later?
      $self->warning("Ticket database: Connection could not be created ($DBI::errstr)");
    }

    $ticket_dbh->disconnect;
  }
}

sub _get_time_now {
  # @private
  my ($sec, $min, $hour, $day, $month, $year) = localtime;
  return sprintf '%d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1, $day, $hour, $min, $sec;
}
1;

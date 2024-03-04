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

package EnsEMBL::Web::RunnableDB;

### Parent class for all the runnabledb classes for different tools
### The child modules of this class are not used by the webserver directly, but are used by hive to actually run the bsubed jobs.
### Error handling: In any child classes, "throw exception('HiveException', 'message ..')" to pass them back to the web server

use strict;
use warnings;

use Data::Dumper;
use DBI;
use IO::Compress::Gzip qw(gzip $GzipError);
use Scalar::Util qw(blessed);
use Storable qw(nfreeze);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::ToolsWarning;
use EnsEMBL::Web::Utils::FileSystem qw(copy_files);
use EnsEMBL::Web::Utils::FileHandler qw(file_put_contents file_append_contents);

use parent qw(Bio::EnsEMBL::Hive::Process);

use constant MAXIMUM_LOG_MESSAGE_WARNINGS => 500; # maximum number of warnings to be added to log_message table per job

sub new {
  ## @override
  ## Redirect all warnings from now onwards to hive database's log_message table
  my $self = shift->SUPER::new(@_);
  $SIG{'__WARN__'} = sub {
    $self->warning($_[0]);
  };
  return $self;
}

sub param_required {
  ## @override
  ## Throws a HiveException in case a param is not defined and is required
  my ($self, $param_name) = @_;

  throw exception('HiveException', "Param '$param_name' is not defined.") unless $self->param_is_defined($param_name);

  return $self->param($param_name);
}

sub work_dir {
  ## Gets/sets the work directory
  ## @return Directory path
  my $self = shift;

  $self->param('work_dir', shift) if @_;

  my $work_dir = $self->param_required('work_dir');

  throw exception('HiveException', 'Work directory could not be found.')  unless -d $work_dir;

  return $work_dir;
}

sub warning {
  ## @override
  ## Adds an entry to a stderr.log file in the work dir along with default action of adding an entry in log_message table
  ## Ignores 'uninitialized' warnings and only allows a maximum number of warnings per runnable (else stderr.log file and db table may grow quickly)
  my ($self, $message, $is_error) = @_;

  if (!$is_error && $message !~ /^SystemCommand/) { # only limit warnings other than SystemCommand messages

    return if $self->{'_too_many_warnings'};
    return if $message =~ /^Use of uninitialized/;

    if (++$self->{_warning_count} > $self->MAXIMUM_LOG_MESSAGE_WARNINGS) {
      $self->{'_too_many_warnings'} = 1;
      $message = q(Number of warnings exceeded the MAXIMUM_LOG_MESSAGE_WARNINGS. No more warnings will be entered. Fix other warnings thrown by this runnable to avoid reaching this limit.);
    }
  }

  try {
    my $work_dir = $self->work_dir;
    file_append_contents("$work_dir/stderr.log", "$message\n", sprintf("%s\n", '=' x 10));
  } catch {
    $self->SUPER::warning(sprintf('Could not print to stderr.log: %s', $_->message), 0) unless $self->{'_failed_to_print_stderr'}++;
  };

  return $self->SUPER::warning($message, $is_error);
}

sub tools_warning {
  ## An extension of the warning method to save the warnings as json that can be parsed by the web server
  ## @param Hashred as expected by ToolsWarning
  my ($self, $params) = @_;
  $self->warning(EnsEMBL::Web::ToolsWarning->new($params)->to_string);
}

sub save_results {
  ## Writes the results to the result table of ticket db (and work directory if needed)
  ## Use this in 'write_output' to save results
  ## @param Job id to write results against
  ## @param Hashref with keys as file names and value as a hashref with following keys (provide empty hashref if no files are required)
  ##  - content   : File content (string or arrayref of strings)
  ##  - location  : Temporary file location from where the file needs to be moved to work dir (only works if 'content' key is missing)
  ##  - delete    : Flag to tell whether to delete the temporary file after copying the file to the new location (only if 'location' key is provided)
  ##  - gzip      : Flag if on, will gzip the file (only works if 'content' key is provided)
  ## @params Arrayref of hashrefs, each goes in result_data column of the individual result table row
  my ($self, $job_id, $files, $result_data) = @_;

  my $work_dir    = $self->work_dir;
  my $result_file = $self->_result_file($job_id);
  my $error;

  if (keys %$files) {

    try {

      # Create result files if file content was provided in 'content' key
      for (grep { exists $files->{$_}{'content'} } keys %$files) {
        my $content = $files->{$_}{'content'};
        if ($files->{$_}{'gzip'}) {
          my $serialised = nfreeze($content);
          gzip(\$serialised => \($content = ""), -LEVEL => 9) or throw exception('HiveException', "GZIP failed: $GzipError");
        }
        file_put_contents("$work_dir/$_", $content);
        delete $files->{$_};
      }

      # Copy files if temporary file location was provided
      if (my @copy_files = grep { $files->{$_}{'location'} } keys %$files) {

        copy_files({ map { $files->{$_}{'location'} => "$work_dir/$_" } @copy_files });
        unlink map { $files->{$_}{'delete'} ? $files->{$_}{'location'} : () } @copy_files;
      }

    } catch {
      $error = $_;
    };
  }

  # Rollback and throw exception if it failed anywhere
  if ($error) {
    unlink $result_file, map { -e "$work_dir/$_" ? "$work_dir/$_" : () } keys %$files;
    throw exception('HiveException', $error); # change the exception type since hive can only handle HiveException properly
  }

  # Now save the result_data to result table
  if (@$result_data) {

    my $ticket_db   = $self->param_required('ticket_db');
    my $ticket_dbh  = DBI->connect(sprintf('dbi:mysql:%s:%s:%s', $ticket_db->{'-dbname'}, $ticket_db->{'-host'}, $ticket_db->{'-port'}), $ticket_db->{'-user'}, $ticket_db->{'-pass'}, { 'PrintError' => 0 });

    if ($ticket_dbh) {
      my $now   = $self->_get_time_now;
      my $sth   = $ticket_dbh->prepare('INSERT INTO `result` (`job_id`, `result_data`, `created_at`) values ' . join(',', map {'(?,?,?)'} @$result_data));
      my $count = $sth->execute(map {($job_id, _to_ensorm_datastructure_string($_ || {}), $now)} @$result_data);

      if (!$count || $count < 1) {
        if (ref($self) =~ /VEP/) {
          $self->tools_warning({ 'message' => 'Too many variants to be displayed on the location page', 'type' => 'VEPWarning' });
        } else {
          throw exception ('HiveException', "Ticket database: Results could not be saved to ticket database.");
        }
      }
    } else {

      throw exception ('HiveException', "Ticket database: Connection could not be created ($DBI::errstr)");
    }

    $ticket_dbh->disconnect;
  }
}

sub _get_time_now {
  # @private
  my ($sec, $min, $hour, $day, $month, $year) = localtime;
  return sprintf '%d-%02d-%02d %02d:%02d:%02d', $year + 1900, $month + 1, $day, $hour, $min, $sec;
}

sub _result_file {
  ## @private
  ## @param Job id
  return sprintf '%s.results_data.json', $_[1];
}

sub _to_ensorm_datastructure_string {
  ## @private
  ## @function
  ## Returns a string representation of an object as it should go in the db
  ## Follows the ORM::EnsEMBL's way to save objects in DataStructure column types (see ORM::EnsEMBL::Rose::CustomColumnValue::DataStructure::_recursive_unbless)
  my ($obj, $_flag) = @_;

  my $datastructure;

  if (ref $obj) {

    $datastructure = blessed $obj ? [ '_ensorm_blessed_object', ref $obj ] : [];

    if (UNIVERSAL::isa($obj, 'HASH')) {
      push @$datastructure, { map _to_ensorm_datastructure_string($_, 1), %$obj };
    } elsif (UNIVERSAL::isa($obj, 'ARRAY')) {
      push @$datastructure, [ map _to_ensorm_datastructure_string($_, 1), @$obj ];
    } else { # scalar ref
      push @$datastructure, $$obj;
    }

    $datastructure = $datastructure->[0] if @$datastructure == 1;

  } else {
    $datastructure = $obj;
  }

  return $_flag ? $datastructure : Data::Dumper->new([ $datastructure ])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(0)->Dump;
}

1;

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

package EnsEMBL::Web::RunnableDB::Blat;

### Hive Process RunnableDB for BLAT

use strict;
use warnings;

use IO::Socket;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::RunnableDB::Blast);

sub setup_executables {
  ## @override
  my ($self, $blast_type) = @_;

  my $blat_bin    = $self->param_required('BLAT_bin_path');
  my $BTOP_script = sprintf '%s/%s', $self->param_required('code_root'), $self->param_required('BLAT_BTOP_script');

  throw exception('HiveException', "$blast_type can not be run with ".__PACKAGE__) unless $blast_type eq 'BLAT';
  throw exception('HiveException', 'BLAT client binary file is either missing or is not executable.') unless -x $blat_bin;
  throw exception('HiveException', 'BLAT to BTOP script is either missing or not accessible.') unless -e $BTOP_script;

  $self->param('BLAT_BTOP_script', $BTOP_script);
}

sub setup_source_file {
  ## @override
  my ($self, $blast_type) = @_;

  my $work_dir      = $self->work_dir;
  my $source_file   = $self->param('source_file') || '';
  my $species       = $self->param('species');
  my $assembly      = $self->param('assembly');
  my $query_command = $self->param('BLAT_query_cmd');

  my ($host, $port, $nib_dir) = split ':', $source_file, 3;
  $host       = '' if $host && $host eq '?';
  $port       = '' if $port && $port eq '?';
  $nib_dir    = '' if $nib_dir && $nib_dir eq '?';

  # if we got host, port from source_file, check server connection
  if ($host && $port) {
    ($host, $port) = $self->_check_server($host, $port);

  } else {

    # in case we didn't get host and port from source_file and there's no alternative query_command to find them
    throw exception('HiveException', "Bad format for BLAT search DB: $source_file. Format should be host:port:nib_path, or provide a query command that returns host:port:nib_path") unless $query_command;

    # host or port is missing in the source file, but we have a query command
    $query_command =~ s/\[SPECIES\]/$species/g;
    $query_command =~ s/\[ASSEMBLY\]/$assembly/g;

    my ($query_bin, @arguments) = split /\s+/, $query_command;
    my $log_file = sprintf '%s/blat_query.log', $work_dir;
    my $out_file = sprintf '%s/blat_query.out', $work_dir;

    my $query = EnsEMBL::Web::SystemCommand->new($self, $query_bin, \@arguments)->execute({'log_file' => $log_file, 'output_file' => $out_file});

    # parse the output of the command to get host:server:nib_path
    if (!$query->error_code && -e $out_file) {
      my @blat_nodes = file_get_contents($out_file, sub { chomp; /:/ ? $_ : undef }); # only keep the lines that have a colon
      for (@blat_nodes) {
        my @segments = split /:/, $_, 3;
        ($host, $port) = $self->_check_server(@segments);
        if ($host && $port) {
          $nib_dir = $segments[2];
          last;
        }
      }
    }
  }

  # can't connect to the host:port parsed from source_file, or the query_command couldn't find BLAT server
  throw exception('HiveException', "BLAT server unavailable", {'fatal' => 0, display_message => 'The BLAT server you are trying to query is temporarily unavailable. Please try resubmitting your job using BLAST as the Search tool rather than BLAT.'}) unless $host && $port;

  $self->param('__host',    $host);
  $self->param('__port',    $port);
  $self->param('__nib_dir', $nib_dir || '/');
}

sub run {
  ## @override
  my $self = shift;

  # Set up the job
  my $blat_bin    = $self->param('BLAT_bin_path');
  my $BTOP_script = $self->param('BLAT_BTOP_script');
  my $host        = $self->param('__host');
  my $port        = $self->param('__port');
  my $nib_dir     = $self->param('__nib_dir');
  my $query_file  = $self->param('__query_file');
  my $raw_output  = $self->param('__results_raw');
  my $tab_output  = $self->param('__results_tab');

  my %output_type_to_result_file = (
    'blast'   => $raw_output, # output for downloading 
    'blast8'  => $tab_output  # output for parsing
  );

  foreach my $output_type (keys %output_type_to_result_file) {

    my $result_file = $output_type_to_result_file{$output_type};
    my $log_file    = "$result_file.log";

    my $blat_command = EnsEMBL::Web::SystemCommand->new($self, $blat_bin, [
      "-out=$output_type", qw(-minScore=0 -minIdentity=0), $host, $port, $nib_dir, $query_file, $result_file
    ])->execute({'log_file' => $log_file});

    # throw exception if process failed
    if (my $error_code = $blat_command->error_code) {
      my ($error_details) = file_get_contents($log_file);
      throw exception('HiveException', $error_details);
    }
  }

  # now both output are available, run the BTOP script to save BTOP alignments to tab output file
  my $log_file = "$raw_output.BTOP.log";
  my $BTOP_command = EnsEMBL::Web::SystemCommand->new($self, $BTOP_script, {
    '--in'  => $raw_output,
    '--out' => $tab_output
  })->execute({'log_file' => $log_file});

  # throw exception if alignment parsing failed
  if (my $error_code = $BTOP_command->error_code) {
    my ($error_details) = file_get_contents($log_file);
    throw exception('HiveException', $error_details);
  }

  return 1;
}

sub _check_server {
  ## @private
  my ($self, $host, $port) = @_;

  my $server = IO::Socket::INET->new(
    PeerAddr  => $host,
    PeerPort  => $port,
    Proto     => 'tcp',
    Type      => SOCK_STREAM,
    Timeout   => 10
  );

  $self->warning($@) if !$server && $@;
  $server->autoflush(1) if $server;

  return $server ? ($host, $port) : ();
}

1;

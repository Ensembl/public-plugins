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

package EnsEMBL::Web::RunnableDB::AssemblyConverter;

### Hive Process RunnableDB for CrossMap assembly converter

use strict;
use warnings;

use IO::Socket;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::RunnableDB);

sub setup_executables {
  ## @override
  my $self = shift;

  my $ac_bin = $self->param_required('AC_bin_path');

  throw exception('HiveException', 'CrossMap package file is either missing or is not executable.') unless -x $ac_bin;
}

sub run {
  ## @override
  my $self = shift;

  # Set up the job
  my $ac_bin      = $self->param('AC_bin_path');
  my $work_dir    = $self->param('work_dir');
  my $data_dir    = $self->param('data_dir');
  my $config      = $self->param('config');
  my $format      = $config->{'format'};
  ## Bit of a hack, but CrossMap treats these formats the same
  $format = 'gff' if $format eq 'gtf'; 
  my $options     = $format;

  $options .= sprintf ' %s/%s', $data_dir, $config->{'chain_file'};
  $options .= sprintf(' %s/%s', $work_dir, $config->{'input_file'});
  if ($format eq 'vcf') {
    $options .= sprintf ' %s/%s', $data_dir, $config->{'fasta_file'};
  }
  $options .= sprintf(' %s/%s', $work_dir, $config->{'output_file'});

  my $log_file    = sprintf('%s/%s.log', $work_dir, $config->{'output_file'});

  my $ac_command = EnsEMBL::Web::SystemCommand->new($self, $ac_bin, $options)->execute({'log_file' => $log_file});

  # throw exception if process failed
  if (my $error_code = $ac_command->error_code) {
    my ($error_details) = file_get_contents($log_file);
    throw exception('HiveException', $error_details);
  }

  ## CrossMap's error reporting is poor, so check it produced actual output
  my $output = $work_dir.'/'.$config->{'output_file'};
  unless (-e $output && -s $output) { 
    my $error_message = 'Output file';
    $error_message   .= -e $output ? ' empty (zero bytes).' : ' not created.';
    my $display_message = 'Sorry, your input file could not be mapped. Please check that your data complies with <a href="/info/website/upload/index.html#formats">file format specifications</a>.';
    throw exception('HiveException', $error_message, {'display_message' => $display_message, 'fatal' => 0});
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

  $server->autoflush(1);

  return !!$server;
}

1;

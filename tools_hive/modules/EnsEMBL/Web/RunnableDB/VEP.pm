=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::RunnableDB::VEP;

### Hive Process RunnableDB for VEP

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);
use Bio::EnsEMBL::VEP::Runner;

sub fetch_input {
  my $self = shift;

  # required params
  $self->param_required($_) for qw(work_dir config job_id);
}

sub run {
  my $self = shift;

  my $work_dir        = $self->param('work_dir');
  my $config          = $self->param('config');
  my $options         = $self->param('script_options') || {};
  my $log_file        = "$work_dir/lsf_log.txt";

  # path for VEP_plugins (gets pushed to INC by VEP::Runner)
  if (my $plugins_path = $self->param('plugins_path')) {
    $options->{'dir_plugins'} = $plugins_path =~ /^\// ? $plugins_path : sprintf('%s/%s', $self->param('code_root'), $plugins_path);
  }

  $options->{$_}  = 1 for qw(force quiet safe vcf stats_text); # we need these options set on always!
  $options->{$_}  = sprintf '%s/%s', $work_dir, delete $config->{$_} for qw(input_file output_file stats_file);
  $options->{$_}  = $config->{$_} eq 'yes' ? 1 : $config->{$_} for grep { defined $config->{$_} && $config->{$_} ne 'no' } keys %$config;
  
  # are we using cache?
  if ($self->param('cache_dir')){
    $options->{"cache"}    = 1;
    $options->{"dir"}      = $self->param('cache_dir');
    $options->{"database"} = 0;

    if(my $fasta_dir = $self->param('fasta_dir')) {
      $options->{"fasta_dir"} = $fasta_dir;
    }
  } else {
    $options->{"database"} = 1;
  }
  
  # send warnings to STDERR
  $options->{"warning_file"} = "STDERR";

  # tell VEP to write an additional output file we'll import to the results table
  $options->{web_output} = $options->{output_file}.'.web';

  # save the result file name for later use
  $self->param('result_file', $options->{'output_file'});
  
  # set reconnect_when_lost()
  my $reconnect_when_lost_bak = $self->dbc->reconnect_when_lost;
  $self->dbc->reconnect_when_lost(1);

  # create a VEP runner and run the job
  my $runner = Bio::EnsEMBL::VEP::Runner->new($options);
  $runner->run;

  # restore reconnect_when_lost()
  $self->dbc->reconnect_when_lost($reconnect_when_lost_bak);

  # tabix index results
  my $out = $options->{output_file};
  if(-e $out) {
    my $tmp = $out.'.tmp';
    system(sprintf('grep "#" %s > %s', $out, $tmp));
    system(sprintf('grep -v "#" %s | sort -k1,1 -k2,2n >> %s', $out, $tmp));
    system("bgzip -c $tmp > $out");
    system("tabix -p vcf $out");
    unlink($tmp);
  }
  
  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $result_web  = $self->param('result_file').".web";
  return 1 unless -e $result_web;

  my @result_keys = qw(chr start end allele_string strand variation_name consequence_type);
  my @rows        = file_get_contents($result_web, sub { chomp; my @cols = split /\t/, $_; return { map { $result_keys[$_] => $cols[$_] } 0..$#result_keys } });

  $self->save_results($job_id, {}, \@rows);

  return 1;
}

1;

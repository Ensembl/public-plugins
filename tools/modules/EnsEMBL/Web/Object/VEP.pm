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

package EnsEMBL::Web::Object::VEP;

use strict;
use warnings;

use EnsEMBL::Web::TmpFile::ToolsOutput;
use EnsEMBL::Web::TmpFile::VcfTabix;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self        = shift;
  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket   or return [];
  my $job         = shift @{ $ticket->job || [] } or return [];
  my $job_data    = $job->job_data->raw;
  my $input_file  = sprintf '%s/%s', $job->job_dir, $job_data->{'input_file'};
  my $format      = $job_data->{'format'};

  if (-T $input_file && $input_file !~ /\.gz$/ && $input_file !~ /\.zip$/) { # TODO - check if the file is binary!
    if (-s $input_file <= 1024) {
      $job_data->{"text_$format"} = join('', file_get_contents($input_file));
    } else {
      my $dir_loc   = $hub->species_defs->ENSEMBL_TMP_DIR_TOOLS;
      my $file_loc  = $input_file =~ s/^$dir_loc\/(temporary|persistent)\/VEP\///r;

      $job_data->{'input_file_type'}  = 'text';
      $job_data->{'input_file_url'}   = sprintf('/%s/vep_download?file=%s;name=%s;persistent=%s;download=1', $hub->species, $file_loc, $file_loc =~ s/.*\///r, $ticket->owner_type eq 'user' ? 1 : 0);
    }
  } else {
    $job_data->{'input_file_type'} = 'binary';
  }

  return [ $job_data ];
}

sub result_files {
  ## Gets the result stats and ouput files
  my $self = shift;

  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->dispatcher_data->{'config'};
    my $job_dir     = $job->job_dir;

    $self->{'_results_files'} = {
      'output_file' => EnsEMBL::Web::TmpFile::VcfTabix->new('filename' => "$job_dir/$job_config->{'output_file'}"),
      'stats_file'  => EnsEMBL::Web::TmpFile::ToolsOutput->new('filename' => "$job_dir/$job_config->{'stats_file'}")
    };
  }

  return $self->{'_results_files'};
}

sub get_all_variants_in_slice_region {
  ## Gets all the result variants for the given job in the given slice region
  ## @param Job object
  ## @param Slice object
  ## @return Array of result data hashrefs
  my ($self, $job, $slice) = @_;

  my $s_name    = $slice->seq_region_name;
  my $s_start   = $slice->start;
  my $s_end     = $slice->end;

  return [ grep {

    my $chr   = $_->{'chr'};
    my $start = $_->{'start'};
    my $end   = $_->{'end'};

    $s_name eq $chr && (
      $start >= $s_start && $end <= $s_end ||
      $start < $s_start && $end <= $s_end && $end > $s_start ||
      $start >= $s_start && $start <= $s_end && $end > $s_end ||
      $start < $s_start && $end > $s_end && $start < $s_end
    )

  } map $_->result_data, $job->result ];
}

1;

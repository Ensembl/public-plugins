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

package EnsEMBL::Web::Object::AssemblyConverter;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_output_file {
  ## Gets the output file for a job
  ## @param Job object
  ## @return Full path to output file
  my ($self, $job) = @_;

  my $job_config  = $job->dispatcher_data->{'config'} or return '';
  my $file        = sprintf '%s/%s', $job->job_dir, $job_config->{'output_file'};

  # for wig format, if the tool failed to produce final wig file, use the intermediate bw file as output if that exists
  $file = "$file.bw" if $job_config->{'format'} eq 'wig' && !-e $file && -e "$file.bw";

  return -e $file && -s $file ? $file : '';
}

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
      $job_data->{"text_$format"} = file_get_contents($input_file);
    } else {
      $job_data->{'input_file_type'}  = 'text';
      $job_data->{'input_file_url'}   = $self->download_url($ticket->ticket_name, {'input' => 1});
    }
  } else {
    $job_data->{'input_file_type'} = 'binary';
  }

  return [ $job_data ];
}

sub handle_download {
  ## Retrieves file contents and outputs direct to Apache request, so that the browser will download it instead of displaying it in the window.
  ## Uses Controller::Download, via url /Download/AssemblyConverter/
  my ($self, $r) = @_;

  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket or return;
  my $job         = $ticket->job->[0] or return;
  my $job_config  = $job->dispatcher_data->{'config'};
  my $is_input    = $hub->param('input'); # is trying to download the input file ?
  my $file        = $is_input ? sprintf('%s/%s', $job->job_dir, $job_config->{'input_file'}) : $self->get_output_file($job);
  my $content     = file_get_contents($file, sub { s/\R/\r\n/r });

  $r->headers_out->add('Content-Type'         => -T $file ? 'text/plain' : 'application/octet-stream');
  $r->headers_out->add('Content-Length'       => length $content);
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s.%s', $ticket->ticket_name, [ split /\./, $file ]->[-1]);

  print $content;
}

sub species_list {
  ## Returns a list of species with Assembly converter specific info
  ## @return Arrayref of hashes with each hash having species specific info
  my $self = shift;

  if (!$self->{'_species_list'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;
    my @species;

    my $chain_files = {};
    foreach ($self->valid_species) {
      my $files = $sd->get_config($_, 'ASSEMBLY_CONVERTER_FILES') || [];
      $chain_files->{$_} = $files if scalar(@$files);
    }

    for (keys %$chain_files) {

      my $mappings = [];
      foreach my $map (@{$chain_files->{$_}||[]}) {
        (my $caption = $map) =~ s/_to_/ -> /;
        push @$mappings, {'caption' => $caption, 'value' => $map};
      }
      my $db_config = $sd->get_config($_, 'databases');

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'mappings'    => $mappings,
      };
    }

    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }

  return $self->{'_species_list'};
}


1;

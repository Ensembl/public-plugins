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

package EnsEMBL::Web::Ticket::AssemblyConverter;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::File::Tools;
use EnsEMBL::Web::Job::AssemblyConverter;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $species   = $hub->param('species');
  my $format    = $hub->param('format');

  $hub->param('text', $hub->param("text_$format"));

  my $file = EnsEMBL::Web::File::Tools->new('hub' => $hub, 'tool' => 'AssemblyConverter');

  my $method    = first { $hub->param($_) } qw(file url userdata text);

  # if no data entered
  throw exception('InputError', 'No input data has been entered') unless $method;

  my ($file_name, $file_path, $description);

  # if input is one of the existing files
  if ($method eq 'userdata') {

    $file_name    = $hub->param('userdata');
    $description  = 'user data';

    $file->init('file' => $file_name);

  # if new file, url or text, upload it to a temporary file location
  } else {

    $description = $hub->param('name') || ($method eq 'text' ? 'pasted data' : ($method eq 'url' ? 'data from URL' : sprintf("%s", $hub->param('file'))));

    my $error = $file->upload('type' => 'no_attach');
    throw exception('InputError', $error) if $error;

    $file_name = $file->write_name;
  }

  # finalise input file path and description
  $file_path    = $file->write_location; 
  $description  = "Assembly conversion of $description in $species";
  $file_name    .= '.'.lc($format) if $file_name !~ /\./ && -T $file_path;
  $file_name    = $file_name =~ s/.*\///r;

  # check file format is matching
  ## TODO VEP can do this - need similar generic functionality in EnsEMBL::IO
  ## Do simple check of file extension for now
  $file_name =~ /\.(\w{2,4}$)/;
  my $extension = lc $1;
  if ($extension !~ /^(txt|gz|zip)$/ && $extension ne lc($format)) {
    throw exception('InputError', 'Your file does not appear to match the selected format.');
  }

  my $job_data;
  foreach ($hub->param) {
    next if $_ =~ /^text/;
    next if $_ eq 'file';
    if ($_ =~ /mappings_for_(\w+)/) {
      next unless $1 eq $species;
      $job_data->{'mapping'} = $hub->param($_); 
    }
    else {
      my @val = $hub->param($_);
      $job_data->{$_} = @val > 1 ? \@val : $val[0];
    } 
  }

  # change file name extensions according to format (remove gz, zip, txt etc) (gz, zip are useless anyway as UserData decompresses the files)
  $file_name  = sprintf '%s.%s', $file_name =~ s/\.[^\/]+$//r, lc $format;

  ## Replace spaces with underscores!
  $file_name =~ s/ /_/g;

  ## Format-specific input tweaks
  if ($format eq 'VCF') {
    ## Extra parameter for VCF
    my @assemblies = split('_to_', $job_data->{'mapping'});
    $job_data->{'fasta_file'} = sprintf('%s/%s.%s.dna.toplevel.fa', lc($species), $species, $assemblies[1]);
  } 
  elsif ($format eq 'WIG') {
    ## WIG is output as BedGraph, so remove extension
    $file_name =~ s/\.wig//;
  }

  $job_data->{'species'}      = $species;
  $job_data->{'chain_file'}   = lc($species).'/'.$job_data->{'mapping'}.'.chain.gz';
  $job_data->{'input_file'}   = $file_name;
  $job_data->{'output_file'}  = "output_$file_name";

  $self->add_job(EnsEMBL::Web::Job::AssemblyConverter->new($self, {
    'job_desc'    => $description,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => $job_data
  }, {
    $file_name    => {'location' => $file_path}
  }));
}

1;

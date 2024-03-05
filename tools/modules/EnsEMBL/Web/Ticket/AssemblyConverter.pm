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

package EnsEMBL::Web::Ticket::AssemblyConverter;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::File::Tools;
use EnsEMBL::Web::Job::AssemblyConverter;
use EnsEMBL::Web::AssemblyConverterConstants qw(INPUT_FORMATS);

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $species   = $hub->param('species');
  my $format    = $hub->param('format');
  my %formats   = map { $_->{'value'} => 1 } @{INPUT_FORMATS()};

  # if no format or invalid format
  throw ('InputError', 'Invalid format') unless $format && $formats{$format};

  $hub->param('text', $hub->param("text_$format"));

  my $method = first { $hub->param($_) } qw(file url text); # precedence order - eg. if file is provided, url is ignored

  # if no data entered
  throw exception('InputError', 'No input data has been entered') unless $method;

  my $description = $hub->param('name') || ($method eq 'text' ? 'pasted data' : ($method eq 'url' ? 'data from URL' : sprintf("%s", $hub->param('file'))));

  my ($file_content, $file_name) = $self->get_input_file_content($method);

  # empty file
  throw exception('InputError', 'No input data has been entered') unless $file_content;

  # finalise input file name and description
  $description  = "Assembly conversion of $description in $species";
  $file_name   .= '.'.lc($format) if $file_name !~ /\./;

  # check file format is matching
  $file_name =~ /\.(\w{2,4}$)/;
  my $extension = lc $1;
  if ($extension !~ /^(txt|gz|zip)$/ && $extension ne lc($format)) {
    throw exception('InputError', 'Your file does not appear to match the selected format.');
  }

  # save all form params to job data
  my $job_data = {};
  foreach ($hub->param) {
    next if $_ =~ /^text/;
    next if $_ eq 'file';

    if ($_ =~ /mappings_for_(\w+)/) {
      next unless $1 eq $species;
      $job_data->{'mapping'} = $hub->param($_);
    } else {
      my @val = $hub->param($_);
      $job_data->{$_} = @val > 1 ? \@val : $val[0];
    }
  }

  # change file name extensions according to format (remove gz, zip, txt etc) (gz, zip are useless anyway as UserData decompresses the files)
  $file_name  = sprintf '%s.%s', $file_name =~ s/\.[^\/]+$//r, lc $format;

  # save final file name to job data
  $job_data->{'input_file'} = $file_name;

  $self->add_job(EnsEMBL::Web::Job::AssemblyConverter->new($self, {
    'job_desc'    => $description,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => $job_data
  }, {
    $file_name    => {'content' => $file_content}
  }));
}

1;

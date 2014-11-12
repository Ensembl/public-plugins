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

package EnsEMBL::Web::Ticket::VEP;

use strict;
use warnings;

use List::Util qw(first);
use Bio::EnsEMBL::Variation::Utils::VEP qw(detect_format);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Command::UserData;
use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Job::VEP;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $species   = $hub->param('species');

  my $method    = first { $hub->param($_) } qw(file url userdata text);

  # if no data entered
  throw exception('InputError', 'No input data has been entered') unless $method;

  my ($file_name, $file_path, $description);

  # if input is one of the existing files
  if ($method eq 'userdata') {

    $file_name    = $hub->param('userdata');
    $description  = 'user data'

  # if new file, url or text, upload it to a temporary file location
  } else {

    $description = $hub->param('name') || ($method eq 'text' ? 'pasted data' : ($method eq 'url' ? 'data from URL' : sprintf("%s", $hub->param('file'))));

    # upload from file/text/url
    my $response = EnsEMBL::Web::Command::UserData->new({'object' => $self->object, 'hub' => $hub})->upload($method); # FIXME - upload method needs to be taken out of EnsEMBL::Web::Command::UserData

    throw exception('InputError', $response && $response->{'error'} ? $response->{'error'} : "Upload failed: $response->{'filter_code'}") unless $response && $response->{'code'};

    my $code      = $response->{'code'};
    my $tempdata  = $hub->session->get_data('type' => 'upload', 'code' => $code);

    throw exception('InputError', "Could not find file with code $code") unless $tempdata && $tempdata->{'filename'};

    $file_name = $tempdata->{'filename'};
  }

  # finalise input file path and description
  $file_path    = EnsEMBL::Web::TmpFile::Text->new('filename' => $file_name)->{'full_path'}; # absolute path of the temporary input file
  $description  = "VEP analysis of $description in $species";
  $file_name    = "$file_name.txt" if $file_name !~ /\./ && -T $file_path;
  $file_name    = $file_name =~ s/.*\///r;

  # detect file format
  my $detected_format;
  first { m/^[^\#]/ && ($detected_format = detect_format($_)) } file_get_contents($file_path);

  my $job_data = { map { my @val = $hub->param($_); $_ => @val > 1 ? \@val : $val[0] } grep { $_ !~ /^text/ && $_ ne 'file' } $hub->param };

  $job_data->{'species'}    = $species;
  $job_data->{'input_file'} = $file_name;
  $job_data->{'format'}     = $detected_format;

  $self->add_job(EnsEMBL::Web::Job::VEP->new($self, {
    'job_desc'    => $description,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => $job_data
  }, {
    $file_name    => {'location' => $file_path}
  }));
}

1;

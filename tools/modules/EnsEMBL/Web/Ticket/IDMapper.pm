=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Ticket::IDMapper;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::File::Tools;
use EnsEMBL::Web::Job::IDMapper;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $species   = $hub->param('species');
  my $file      = EnsEMBL::Web::File::Tools->new('hub' => $hub, 'tool' => 'IDMapper', 'empty' => 1);
  my $method    = first { $hub->param($_) } qw(file url text);
  my $desc      = $hub->param('name') || sprintf('ID mapping of %s', $method eq 'text' ? 'pasted data' : ($method eq 'url' ? 'data from URL' : sprintf("%s", $hub->param('file'))));
  my $error     = $file->upload('type' => 'no_attach');

  throw exception('InputError', $error) if $error;

  my $file_name = $file->write_name;
  my $file_path = $file->absolute_write_path;

  $self->add_job(EnsEMBL::Web::Job::IDMapper->new($self, {
    'job_desc'    => $desc,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => {
      'species'     => $species,
      'input'       => { 'type' => $method, 'url' => $hub->param('url') || '', 'file' => $hub->param('file') || '' }, # save this info to pre-populate fields when editing existing job
      'input_file'  => $file_name
    }
  }, {
    $file_name    => {'location' => $file_path}
  }));
}

1;

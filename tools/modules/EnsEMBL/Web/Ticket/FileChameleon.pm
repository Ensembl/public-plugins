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

package EnsEMBL::Web::Ticket::FileChameleon;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::FileChameleon;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $species   = $hub->param('species');

    # if no data found in file/url
  throw exception('InputError', 'No input data is present') unless $hub->param('files_list');
  
  $self->add_job(EnsEMBL::Web::Job::FileChameleon->new($self, {
    'job_desc'    => $hub->param('name') ? $hub->param('name') : "data from URL",
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => {
      'species'         => $species,
      'file_url'        => $hub->param('files_list'),  
      'format'          => $hub->param('format'),      
      'chr_filter'      => $hub->param('chr_filter') != 'null' ? $hub->param('chr_filter') : '',
      'add_transcript'  => $hub->param('add_transcript') ? 1 : '',
      'remap_patch'     => $hub->param('remap_patch') ? 1 : '',
      'long_genes'      => $hub->param('long_genes') != 'null' ? $hub->param('long_genes') : '',
      'just_download'   => !$hub->param('remap_patch') && $hub->param('long_genes') eq 'null' && !$hub->param('add_transcript') && !$hub->param('chr_filter') eq 'null' ? 1 : '',
    }
  }));
}

1;

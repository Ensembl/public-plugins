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

package EnsEMBL::Web::JSONServer::Tools::Blast;

use strict;
use warnings;

use EnsEMBL::Web::BlastConstants;

use base qw(EnsEMBL::Web::JSONServer::Tools);

sub object_type { 'Blast' }

sub retrieve_accession {

}

sub json_read_file {
  my $self        = shift;
  my $hub         = $self->hub;
  my $cgi         = $hub->input;
  my $max_size    = int(MAX_SEQUENCE_LENGTH() * MAX_NUM_SEQUENCES() * 1.1);
  my $filename    = $cgi->param('query_file');

  if ($filename =~ /\.(fa|txt)$/ && $cgi->uploadInfo($filename)->{'Content-Type'} =~ /^(application|text)/) {

    my $filehandle  = $cgi->upload('query_file');
    my $filecontent = '';

    while (<$filehandle>) {
      $filecontent .= $_;
      if (length($filecontent) > $max_size) { # FIXME - find an alternative!
        my $limit = $max_size / 1024;
        my $unit  = 'KB';
        if ($limit > 1024) {
          $limit  = $limit / 1024;
          $unit   = 'MB';
        }
        return {'file_error' => sprintf 'Uploaded file should not be more than %s %s.', int($limit), $unit};
      }
    }

    return {'file' => $filecontent};
  }

  return {'file_error' => sprintf 'Uploaded file should be of type plain text or FASTA.'};
}

1;

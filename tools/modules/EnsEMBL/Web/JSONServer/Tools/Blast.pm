package EnsEMBL::Web::JSONServer::Tools::Blast;

use strict;
use warnings;

use base qw(EnsEMBL::Web::JSONServer::Tools);

sub object_type { 'Blast' }

sub retrieve_accession {

}

sub json_read_file {
  my $self        = shift;
  my $hub         = $self->hub;
  my $cgi         = $hub->input;
  my $max_size    = $hub->species_defs->TOOLS_MAX_FILE_UPLOAD_CHARS || 100 * 1024;
  my $filename    = $cgi->param('query_file');

  if ($filename =~ /\.(fa|txt)$/ && $cgi->uploadInfo($filename)->{'Content-Type'} =~ /^(application|text)/) {

    my $filehandle  = $cgi->upload('query_file');
    my $filecontent = '';

    while (<$filehandle>) {
      $filecontent .= $_;
      if (length($filecontent) > $max_size) { # FIXME - find an alternative!
        return {'file_error' => sprintf 'Uploaded file should not be more than %s Kb.', $max_size / 1024};
      }
    }

    return {'file' => $filecontent};
  }

  return {'file_error' => sprintf 'Uploaded file should be of type plain text or FASTA.'};
}

1;

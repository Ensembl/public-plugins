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

package EnsEMBL::Web::JSONServer::Tools::Blast;

use strict;
use warnings;

use JSON;
use EnsEMBL::Web::BlastConstants qw(MAX_SEQUENCE_LENGTH MAX_NUM_SEQUENCES);
use Bio::EnsEMBL::Registry;
use EnsEMBL::Web::ExtIndex;

use parent qw(EnsEMBL::Web::JSONServer::Tools);

sub object_type { 'Blast' }

sub json_fetch_sequence {
  my ($self, $on_update) = @_;
  my $hub = $self->hub;
  my $id  = $hub->param('id') or return;
  my @seqs;

  for ($self->_possible_dbs($id)) {
    $on_update->([ $_ ]) if $on_update;
    @seqs = $hub->get_ext_seq($_, {'id' => $id});
    last if @seqs && $seqs[0]{'sequence'};
  }

  return $self->call_js_panel_method($seqs[0]{'sequence'}
    ? ('addSequences', [ join "\n\n", map $_->{'sequence'}, @seqs ])
    : ('showError', [ $seqs[0]{'error'} || "Could not find any sequence for $id." ])
  );
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

    for ($filehandle->getlines) {
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

sub _possible_dbs {
  ## @private
  my ($self, $id) = @_;
  my $hub       = $self->hub;
  my $ext_dbs   = $hub->species_defs->ENSEMBL_EXTERNAL_DATABASES;

  return qw(ENSEMBL)  if $id =~ /^ENS/;
  return qw(CCDS)     if $id =~ /^CCDS/ && exists $ext_dbs->{'CCDS'};

  return qw(REST ENSEMBL PUBLIC);
}

# Used in species selector (Taxonselector)
sub json_fetch_species {
  my $self = shift;
  my $hub = $self->hub;
  $self->{species_selector_data} = $self->getSpeciesSelectorData();
  $self->{species_selector_data}->{internal_node_select} = 1;
  my @dyna_tree = $self->create_tree();
  return { json => \@dyna_tree };
}

1;

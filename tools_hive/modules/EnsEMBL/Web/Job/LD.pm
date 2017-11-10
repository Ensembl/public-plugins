=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Job::LD;

### plugin to add extra parameters to LD job before submitting it to Hive dispatcher

use strict;
use warnings;

use previous qw(prepare_to_dispatch);

sub prepare_to_dispatch {
  my $self              = shift;
  my $data              = $self->PREV::prepare_to_dispatch(@_) or return;
  my $rose_object       = $self->rose_object;
  my $hub               = $self->hub;
  my $sd                = $hub->species_defs;
  my $c = $sd->ENSEMBL_VCF_COLLECTIONS;
  $data->{vcf_config} = $c->{'CONFIG'};
  $data->{data_file_base_path} = $sd->DATAFILE_BASE_PATH;
  $data->{vcf_tmp_dir} = $sd->ENSEMBL_TMP_DIR;
#  $data->{ld_binary}    = $sd->ENSEMBL_LD_VCF_FILE;
  $data->{ld_binary}    = '/homes/ens_adm26/sandbox/ensembl-variation/C_code/ld_vcf';
  $data->{ld_tmp_space} = $sd->ENSEMBL_TMP_TMP;
  my $dba =   $hub->database('variation', $rose_object->species);
  my $dbc = $dba->dbc;
  $data->{db_params}  = {
    dbname => $dbc->dbname,
    user => $dbc->user,
    host => $dbc->host,
    pass => $dbc->password,
    port => $dbc->port,
  };
  $data->{species} = $rose_object->species; 
  return $data;
}

1;

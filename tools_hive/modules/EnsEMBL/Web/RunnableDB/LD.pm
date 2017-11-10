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

package EnsEMBL::Web::RunnableDB::LD;

### Hive Process RunnableDB for LD

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);
use Bio::EnsEMBL::Registry;
use FileHandle;
use Bio::EnsEMBL::Variation::DBSQL::LDFeatureContainerAdaptor;

sub fetch_input {
  my $self = shift;

  # required params
#  $self->param_required($_) for qw(work_dir config job_id);
}

sub run {
  my $self = shift;

  my $working_dir = $self->param('working_dir');
  my $output_file = $self->param('output_file');
  my $input_file = $self->param('input_file');
  my $ld_binary = $self->param('ld_binary');
  my $ld_tmp_space  = $self->param('ld_tmp_space');
  my $config = $self->param('config');

  my $vcf_config = $self->param('vcf_config');
  my $data_file_base_path = $self->param('data_file_base_path');
  my $vcf_tmp_dir = $self->param('vcf_tmp_dir');

  my $analysis = $config->{'ld_calculation'};
  my @populations = ();
  if (ref($config->{'populations'}) eq "ARRAY") {
    @populations = @{$config->{'populations'}};
  } else {
    @populations = ($config->{'populations'});
  }

  my $db_params = $self->param('db_params');
  my $dbname = $db_params->{'dbname'};
  my $host = $db_params->{'host'};
  my $user = $db_params->{'user'};
  my $pass = $db_params->{'pass'};
  my $port = $db_params->{'port'};

  my $species = $self->param('species');

  my $registry = 'Bio::EnsEMBL::Registry';
  $registry->load_registry_from_db(
    -host => $host,
    -user => $user,
    -pass => $pass,
    -port => $port,
    -species => $species,
  );

  my $vdba = $registry->get_DBAdaptor($species, 'variation');
  $vdba->vcf_config_file($vcf_config);
  $vdba->vcf_root_dir($data_file_base_path);
  $vdba->vcf_tmp_dir($vcf_tmp_dir);
  $vdba->use_vcf(1);

  my $cdba = $registry->get_DBAdaptor($species, 'core');
  my $population_adaptor = $vdba->get_PopulationAdaptor;
  my $variation_adaptor = $vdba->get_VariationAdaptor;
  my $slice_adaptor = $cdba->get_SliceAdaptor;

  $Bio::EnsEMBL::Variation::DBSQL::LDFeatureContainerAdaptor::VCF_BINARY_FILE = $ld_binary;
  $Bio::EnsEMBL::Variation::DBSQL::LDFeatureContainerAdaptor::TMP_PATH        = $ld_tmp_space;

  my $ld_feature_container_adaptor = $vdba->get_LDFeatureContainerAdaptor;
  my $min_d_prime_threshold = $config->{'d_prime'};
  my $min_r2_threshold = $config->{'r2'};
  my $window_size = $config->{'window_size'};
  $ld_feature_container_adaptor->min_r2($min_r2_threshold);
  $ld_feature_container_adaptor->min_d_prime($min_d_prime_threshold);
  $ld_feature_container_adaptor->max_snp_distance($window_size);

  my $bin = $ld_feature_container_adaptor->vcf_executable;

  if ($analysis eq 'region') {
    my @regions = @{$self->parse_input("$working_dir/$input_file")};
    foreach my $region (@regions) {
      my ($chromosome, $start, $end) = split /\s/, $region;
      my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $start, $end);
      foreach my $population_name (@populations) {
        my $population = $population_adaptor->fetch_by_name($population_name);
        my $population_id = $population->dbID;
        my $ld_feature_container = $ld_feature_container_adaptor->fetch_by_Slice($slice, $population);
        $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id\_$chromosome\_$start\_$end");
      }
    }
  }
  elsif ($analysis eq 'pairwise') {
    my @variants = @{$self->parse_input("$working_dir/$input_file")};
    my @vfs = ();
    foreach my $variant (@variants) {
      my $vf = $variation_adaptor->fetch_by_name($variant)->get_all_VariationFeatures->[0];
      push @vfs, $vf;
    }
    my $vf_count = scalar @vfs;
    foreach my $population_name (@populations) {
      my $population = $population_adaptor->fetch_by_name($population_name);
      my $population_id = $population->dbID;
      my $ld_feature_container = $ld_feature_container_adaptor->fetch_by_VariationFeatures(\@vfs, $population);
      $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id");
    }
  }
  elsif ($analysis eq 'center') {
    my @variants = @{$self->parse_input("$working_dir/$input_file")};
    foreach my $variant (@variants) {
      my $vf = $variation_adaptor->fetch_by_name($variant)->get_all_VariationFeatures->[0];
      foreach my $population_name (@populations) {
        my $population = $population_adaptor->fetch_by_name($population_name);
        my $population_id = $population->dbID;
        my $ld_feature_container = $ld_feature_container_adaptor->fetch_by_VariationFeature($vf, $population);
        $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id\_$variant");
      }
    }
  }
  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  return 1;
}

sub parse_input {
  my $self = shift;
  my $file = shift;
  my @input = ();
  my $fh = FileHandle->new($file, 'r');
  while (<$fh>) {
    chomp;
    s/^\s+|(\s+|\R)$//g;
    push @input, $_;
  }
  $fh->close;
  return \@input;
}

sub ld_feature_container_2_file {
  my $self = shift;
  my $container = shift;
  my $output_file = shift;
  my $no_vf_attribs = 0;
  my $fh = FileHandle->new($output_file, 'w');
  foreach my $ld_hash (@{$container->get_all_ld_values($no_vf_attribs)}) {
    my $d_prime = $ld_hash->{d_prime};
    my $r2 = $ld_hash->{r2};
    my $variation1 = $ld_hash->{variation_name1};
    my $variation2 = $ld_hash->{variation_name2};
    my $vf1 = $ld_hash->{variation1};
    my $vf2 = $ld_hash->{variation2};
    my $vf1_start = $vf1->seq_region_start;
    my $vf1_seq_region_name = $vf1->seq_region_name;
    my $vf2_start = $vf2->seq_region_start;
    my $vf2_seq_region_name = $vf2->seq_region_name;

    print $fh join("\t", $variation1, "$vf1_seq_region_name:$vf1_start", $variation2, "$vf2_seq_region_name:$vf2_start", $r2, $d_prime), "\n";
  }
  $fh->close;
}

1;

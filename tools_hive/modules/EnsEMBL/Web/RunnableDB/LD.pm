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
use List::Util qw(uniq);
use POSIX;

sub fetch_input {
  my $self = shift;
}

sub run {
  my $self = shift;
  my $working_dir = $self->param('work_dir');
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
  $self->param('variation_adaptor', $variation_adaptor);
  my $slice_adaptor = $cdba->get_SliceAdaptor;

  $Bio::EnsEMBL::Variation::DBSQL::LDFeatureContainerAdaptor::VCF_BINARY_FILE = $ld_binary;
  $Bio::EnsEMBL::Variation::DBSQL::LDFeatureContainerAdaptor::TMP_PATH        = $ld_tmp_space;

  my $ld_feature_container_adaptor = $vdba->get_LDFeatureContainerAdaptor;
  my $min_d_prime_threshold = $config->{'d_prime'};
  my $min_r2_threshold = $config->{'r2'};
  my $window_size = $config->{'window_size'};
  $window_size = ceil($window_size / 2);
  $ld_feature_container_adaptor->min_r2($min_r2_threshold);
  $ld_feature_container_adaptor->min_d_prime($min_d_prime_threshold);
  $ld_feature_container_adaptor->max_snp_distance($window_size);

  my $bin = $ld_feature_container_adaptor->vcf_executable;
  my $ld_feature_container;
  if ($analysis eq 'region') {
    my @regions = @{$self->parse_input("$working_dir/$input_file")};
    foreach my $region (@regions) {
      my ($chromosome, $start, $end) = split /\s+/, $region;
      my $slice = $slice_adaptor->fetch_by_region('chromosome', $chromosome, $start, $end);
      if ($slice) {
        foreach my $population_name (@populations) {
          my $population = $population_adaptor->fetch_by_name($population_name);
          my $population_id = $population->dbID;
          try {
           $ld_feature_container = $ld_feature_container_adaptor->fetch_by_Slice($slice, $population);
          } catch {
            $self->warning("$_");
            throw exception('HiveException', "Error occurred during LD calculation.");
          };
          $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id\_$chromosome\_$start\_$end", $population_name);
        }
      } else {
        $self->tools_warning({ 'message' => "Couldn't fetch region $region for species $species", 'type' => 'LDWarning' });
      }
    }
  }
  elsif ($analysis eq 'pairwise') {
    my @variants = @{$self->parse_input("$working_dir/$input_file")};
    my @vfs = ();
    foreach my $variant (@variants) {
      my $vf = $self->get_variation_feature($variant);
      next if (!$vf);
      push @vfs, $vf;
    }
    my $vf_count = scalar @vfs;
    if ($vf_count > 1) {
      foreach my $population_name (@populations) {
        my $population = $population_adaptor->fetch_by_name($population_name);
        my $population_id = $population->dbID;
        try {
          $ld_feature_container = $ld_feature_container_adaptor->fetch_by_VariationFeatures(\@vfs, $population);
        } catch {
          $self->warning("$_");
          throw exception('HiveException', "Error occurred during LD caclculation.");
        };
        $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id", $population_name);
      }
    } else {
      $self->tools_warning({ 'message' => "Couldn't fetch enough variants for LD calculations", 'type' => 'LDWarning' });
    }
  }
  elsif ($analysis eq 'center') {
    my @variants = @{$self->parse_input("$working_dir/$input_file")};
    foreach my $variant (@variants) {
      my $vf = $self->get_variation_feature($variant);
      if ($vf) {
        foreach my $population_name (@populations) {
          my $population = $population_adaptor->fetch_by_name($population_name);
          my $population_id = $population->dbID;
          try {
            $ld_feature_container = $ld_feature_container_adaptor->fetch_by_VariationFeature($vf, $population);
          } catch {
            $self->warning("$_");
            throw exception('HiveException', "Error occurred during LD caclculation.");
          };
          $self->ld_feature_container_2_file($ld_feature_container, "$working_dir/$population_id\_$variant", $population_name);
        }
      } else {
        $self->tools_warning({ 'message' => "Couldn't run LD calculations for $variant. Variant has either multiple mappings or is not located on a chromosome.", 'type' => 'LDWarning' });
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

sub get_variation_feature {
  my $self = shift;
  my $variant = shift; 
  my $variation_adaptor = $self->param('variation_adaptor');
  my $species = $self->param('species');

  my $variation = $variation_adaptor->fetch_by_name($variant); 
  if (!$variation) {
    $self->tools_warning({ 'message' => "Couldn't fetch variation for $variant", 'type' => 'LDWarning' });
    return undef;
  }   
  my @evidence_values = @{$variation->get_all_evidence_values};
  $self->warning("$species @evidence_values");
  if ($species eq 'Homo_sapiens' & !(grep {$_ eq '1000Genomes'} @evidence_values)) {
    $self->tools_warning({ 'message' => "Variant $variant has no 1000 Genomes data.", 'type' => 'LDWarning' });
  }
  my @variation_features = grep {$_->slice->is_reference} @{$variation->get_all_VariationFeatures};
  my $vf = $variation_features[0];
  if (scalar @variation_features > 1) {
    my $chrom = $vf->seq_region_name; 
    my $start = $vf->seq_region_start; 
    my $end = $vf->seq_region_end;
    $self->tools_warning({ 'message' => "Variation $variant has more than 1 mapping to the genome. Selected  $chrom:$start-$end as representative mapping.", 'type' => 'LDWarning' });
  }
  return $vf;
}

sub parse_input {
  my $self = shift;
  my $file = shift;
  my @input = ();
  my $fh = FileHandle->new($file, 'r');
  while (<$fh>) {
    chomp;
    s/^\s+|(\s+|\R)$//g;
    push @input, $_ if ($_ ne '');
  }
  $fh->close;
  my @uniq_input = uniq @input;
  return \@uniq_input;
}

sub ld_feature_container_2_file {
  my $self = shift;
  my $container = shift;
  my $output_file = shift;
  my $population_name = shift;
  my $working_dir = $self->param('work_dir');
  my $config = $self->param('config');
  my $all = $config->{'joined_output_file_name'};
  my $no_vf_attribs = 0;
  my $fh = FileHandle->new($output_file, 'w');
  open(my $fh_all, '>>', "$working_dir/$all") or throw exception('HiveException', "Failed to open output file $working_dir/$all: $!");
  foreach my $ld_hash (@{$container->get_all_ld_values($no_vf_attribs)}) {
    my $d_prime = $ld_hash->{d_prime};
    my $r2 = $ld_hash->{r2};
    my $variation1 = $ld_hash->{variation_name1};
    my $variation2 = $ld_hash->{variation_name2};
    my $vf1 = $ld_hash->{variation1};
    my $vf2 = $ld_hash->{variation2};
    my $vf1_start = $vf1->seq_region_start;
    my $vf1_end = $vf1->seq_region_end;
    my $vf1_seq_region_name = $vf1->seq_region_name;
    my $vf1_location = "$vf1_seq_region_name:$vf1_start";
    $vf1_location .= "-$vf1_end" if ($vf1_start != $vf1_end);
    my $vf1_consequence = $vf1->display_consequence; 
    my $vf1_evidence = join(',', @{$vf1->get_all_evidence_values});
    my $vf2_start = $vf2->seq_region_start;
    my $vf2_end = $vf2->seq_region_start;
    my $vf2_seq_region_name = $vf2->seq_region_name;
    my $vf2_location = "$vf2_seq_region_name:$vf2_start";
    $vf2_location .= "-$vf2_end" if ($vf2_start != $vf2_end);
    my $vf2_consequence = $vf2->display_consequence;
    my $vf2_evidence = join(',', @{$vf2->get_all_evidence_values});
    print $fh join("\t", $variation1, $vf1_location, $vf1_consequence, $vf1_evidence, $variation2, $vf2_location, $vf2_consequence, $vf2_evidence, $r2, $d_prime), "\n";
    print $fh_all join("\t", $variation1, $vf1_location, $vf1_consequence, $vf1_evidence, $variation2, $vf2_location, $vf2_consequence, $vf2_evidence, $r2, $d_prime, $population_name), "\n";
  }
  $fh->close;
  $fh_all->close;
}

1;

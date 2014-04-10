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

package EnsEMBL::Web::Job::VEP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Job);

sub process_for_hive_submission {
  ## @override
  my $self        = shift;
  my $rose_object = $self->rose_object;
  my $job_data    = $rose_object->job_data;
  my $species     = $job_data->{'species'};
  my $sp_details  = $self->_species_details($species);
  my $vep_configs = {};

  $vep_configs->{'format'}  = $job_data->{'format'};
  $vep_configs->{'species'} = lc $species;

  # refseq
  $vep_configs->{'refseq'}  = 'yes' if $sp_details->{'refseq'} && ($job_data->{'core_type'} // '') eq 'refseq';

  # filters
  my $frequency_filtering = $job_data->{'frequency'};

  if ($species eq 'Homo_sapiens') {

    if ($frequency_filtering eq 'common') {
      $vep_configs->{'filter_common'} = 'yes';
    } elsif($frequency_filtering eq 'advanced') {
      $vep_configs->{'check_frequency'} = 'yes';
      $vep_configs->{$_} = $job_data->{$_} for qw(freq_pop freq_freq freq_gt_lt freq_filter);
    }
  }

  my $summary = $job_data->{'summary'};
  if ($summary ne 'no') {
    $vep_configs->{$summary} = 'yes';
  }

  for (grep $sp_details->{$_}, qw(regulatory sift polyphen)) {
    my $value = $job_data->{$_ . ($_ eq 'regulatory' ? "_$species" : '')};
    $vep_configs->{$_} = $value if $value && $value ne 'no';
  }

  # regulatory
  if($sp_details->{'regulatory'} && $vep_configs->{'regulatory'}) {

    # cell types
    if($vep_configs->{'regulatory'} eq 'cell') {
      my @cell_types = grep { length $_ } ref $job_data->{"cell_type_$species"} ? @{$job_data->{"cell_type_$species"}} : $job_data->{"cell_type_$species"};
      $vep_configs->{'cell_type'} = join ",", @cell_types if scalar @cell_types;
    }

    $vep_configs->{'regulatory'} = 'yes';
  }

  # check existing
  my $check_ex = $job_data->{'check_existing'};

  if ($check_ex) {
    if($check_ex eq 'check') {
      $vep_configs->{'check_existing'} = 'yes';
    } elsif ($check_ex eq 'allele') {
      $vep_configs->{'check_existing'} = 'yes';
      $vep_configs->{'check_alleles'} = 'yes';
    }

    # MAFs in human
    if ($species eq 'Homo_sapiens') {
      ($job_data->{'gmaf'} // '') eq 'yes' and $vep_configs->{$_} = 'yes' for qw(gmaf maf_1kg maf_esp);
    }
  }

  # i/o files
  $vep_configs->{'input_file'}  = $job_data->{'input_file'};
  $vep_configs->{'output_file'} = 'output.vcf';
  $vep_configs->{'stats_file'}  = 'stats.txt';

  # extra and identifiers
  $job_data->{$_} and $vep_configs->{$_} = $job_data->{$_} for qw(numbers canonical domains biotype symbol ccds protein hgvs coding_only);

  # check for incompatibilities
  if ($vep_configs->{'most_severe'} || $vep_configs->{'summary'}) {
    delete $vep_configs->{$_} for(qw(coding_only protein symbol sift polyphen ccds canonical numbers domains biotype));
  }

  return { 'species' => $vep_configs->{'species'}, 'work_dir' => $rose_object->job_dir, 'config' => $vep_configs };
}

sub _species_details {
  ## @private
  my ($self, $species) = @_;

  my $sd        = $self->hub->species_defs;
  my $db_config = $sd->get_config($species, 'databases');

  return {
    'sift'        => $db_config->{'DATABASE_VARIATION'}{'SIFT'},
    'polyphen'    => $db_config->{'DATABASE_VARIATION'}{'POLYPHEN'},
    'regulatory'  => $sd->get_config($species, 'REGULATORY_BUILD'),

    # at the moment only human, chicken and mouse have RefSeqs in their otherfeatures DB
    # there's no config for this currently so species are listed manually
    'refseq'      => grep({ $_ eq $species } qw(Gallus_gallus Homo_sapiens Mus_musculus)) && $db_config->{'DATABASE_OTHERFEATURES'}
  };
}

1;

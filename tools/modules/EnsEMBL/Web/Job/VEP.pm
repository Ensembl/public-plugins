=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

use EnsEMBL::Web::VEPConstants qw(REST_DISPATCHER_FILESIZE_LIMIT);

use parent qw(EnsEMBL::Web::Job);

sub prepare_to_dispatch {
  ## @override
  my $self        = shift;
  my $rose_object = $self->rose_object;
  my $job_data    = $rose_object->job_data;
  my $species     = $job_data->{'species'};
  my $sp_details  = $self->_species_details($species);
  my $sd          = $self->hub->species_defs;
  my $vep_configs = {};

  $vep_configs->{'species'} = lc $species;

  # select transcript set
  $vep_configs->{'refseq'}  = 'yes' if $sp_details->{'refseq'} && ($job_data->{'core_type'} // '') eq 'refseq';
  $vep_configs->{'merged'}  = 'yes' if $sp_details->{'refseq'} && ($job_data->{'core_type'} // '') eq 'merged';
  $vep_configs->{'gencode_basic'} = 'yes' if ($job_data->{'core_type'} // '') eq 'gencode_basic';

  # filters
  my $frequency_filtering = $job_data->{'frequency'};

  if ($species eq 'Homo_sapiens') {

    if ($frequency_filtering eq 'common') {
      $vep_configs->{'filter_common'} = 'yes';
    } elsif($frequency_filtering eq 'advanced') {
      $vep_configs->{'check_frequency'} = 'yes';
      $vep_configs->{$_} = $job_data->{$_} || 0 for qw(freq_pop freq_freq freq_gt_lt freq_filter);
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

  # buffer size
  $vep_configs->{buffer_size} = $job_data->{buffer_size};

  # regulatory
  if($sp_details->{'regulatory'} && $vep_configs->{'regulatory'}) {

    # cell types
    if($vep_configs->{'regulatory'} eq 'cell') {
      my @cell_types = grep { length $_ } ref $job_data->{"cell_type_$species"} ? @{$job_data->{"cell_type_$species"}} : $job_data->{"cell_type_$species"};
      $vep_configs->{'cell_type'} = join ",", @cell_types if scalar @cell_types;
    }

    $vep_configs->{'regulatory'} = 'yes';
    $vep_configs->{'buffer_size'} = 500 if ($vep_configs->{buffer_size} > 500);
  }

  # check existing
  my $check_ex = $job_data->{'check_existing'};

  if ($check_ex && $check_ex ne 'no') {
    if($check_ex eq 'yes') {
      $vep_configs->{'check_existing'} = 'yes';
    } elsif ($check_ex eq 'no_allele') {
      $vep_configs->{'check_existing'} = 'yes';
      $vep_configs->{'no_check_alleles'} = 'yes';
    }

    # Allele frequencies in human
    if ($species eq 'Homo_sapiens') {
      foreach my $pop_af (qw(af af_1kg af_esp af_gnomad)) {
        $vep_configs->{$pop_af} = $job_data->{$pop_af} if ($job_data->{$pop_af});
      }
      $vep_configs->{'pubmed'} = $job_data->{'pubmed'} if $job_data->{'pubmed'};
    }
  }

  # Variant synonyms
  if ($species eq 'Sus_scrofa' || $species eq 'Homo_sapiens') {
    $vep_configs->{'var_synonyms'} = $job_data->{'var_synonyms'} if $job_data->{'var_synonyms'};
  }

  # i/o files
  $vep_configs->{'input_file'}  = $job_data->{'input_file'};
  $vep_configs->{'output_file'} = 'output.vcf';
  $vep_configs->{'stats_file'}  = 'stats.txt';

  # shifting
  my $check_shifting = $job_data->{'shift_3prime'};

  if ($check_shifting && $check_shifting ne 'no') {
    $vep_configs->{'shift_3prime'} = 1;
    if($check_shifting eq 'shift_genomic') {
      $vep_configs->{'shift_genomic'} = 1;
    }
  }

  # extra and identifiers
  $job_data->{$_} and $vep_configs->{$_} = $job_data->{$_} for qw(numbers canonical domains biotype symbol transcript_version ccds protein uniprot hgvs coding_only all_refseq tsl mane appris failed distance);

  $vep_configs->{distance} = 0 if($job_data->{distance} eq '0' || $job_data->{distance} eq "");

  # check for incompatibilities
  if ($vep_configs->{'most_severe'} || $vep_configs->{'summary'}) {
    delete $vep_configs->{$_} for(qw(coding_only protein symbol sift polyphen ccds canonical numbers domains biotype tsl appris mane));
  }

  # plugins
  $vep_configs->{plugin} = $self->_configure_plugins($job_data);

  return { 'species' => $vep_configs->{'species'}, 'work_dir' => $rose_object->job_dir, 'config' => $vep_configs };
}

sub _configure_plugins {
  my $self = shift;
  my $job_data = shift;
  
  # get plugin config into a hash keyed on key
  my $pl = $self->hub->species_defs->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG');
  return [] unless $pl;
  my %plugin_config = map {$_->{key} => $_} @{$pl->{plugins} || []};
  
  my @active_plugins = ();
  
  foreach my $pl_key(grep {$_ =~ /^plugin\_/ && $job_data->{$_} eq $_} keys %$job_data) {
    
    $pl_key =~ s/^plugin\_//;
    my $plugin = $plugin_config{$pl_key};
    next unless $plugin;
    
    my @params;
    
    foreach my $param(@{$plugin->{params}}) {
      
      my $param_clone = $param;

      # links to something in the form
      if($param_clone =~ /^\@/) {
        $param_clone =~ s/^\@//;
        
        my @matched = ();
        
        # fuzzy match?
        if($param_clone =~ /\*/) {
          $param_clone =~ s/\*/\.\*/;
          @matched = grep {$_->{name} =~ /$param_clone/} @{$plugin->{form}};
        }
        
        else {
          @matched = grep {$_->{name} eq $param_clone} @{$plugin->{form}};
        }
        
        foreach my $el(@matched) {
          my $val = $job_data->{'plugin_'.$pl_key.'_'.$el->{name}};

          $val = join(',', @$val) if $val && ref($val) eq 'ARRAY';

          # remove any spaces
          $val =~ s/,\s+/,/g if $val && $val =~ /,/;
          
          if(defined($val) && $val ne '' && $val ne 'no') {
            push @params, $val;
          }
        }
      }
      
      # otherwise just plain text
      else {
        push @params, $param_clone;
      }
    }
    
    push @active_plugins, join(",", ($pl_key, @params));
  }
  
  return \@active_plugins;
}

sub get_dispatcher_class {
  ## For smaller VEP jobs, we use the VEP REST API dispatcher, otherwise whatever is configured in SiteDefs.
  my ($self, $data) = @_;

  my $filesize  = -s join '/', $data->{'work_dir'}, $data->{'config'}->{'input_file'};
  my $limit     = REST_DISPATCHER_FILESIZE_LIMIT || 0;

  return $limit > $filesize ? 'VEPRest' : undef;
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
    'refseq'      => $db_config->{'DATABASE_OTHERFEATURES'} && $sd->get_config($species, 'VEP_REFSEQ')
  };
}

1;

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

  #Web form submits species_url but VEP expects production_name 
  $vep_configs->{'species'} = $sd->get_config($species, 'SPECIES_PRODUCTION_NAME');

  # select transcript set
  $vep_configs->{'refseq'}  = 'yes' if $sp_details->{'refseq'} && ($job_data->{'core_type'} // '') eq 'refseq';
  $vep_configs->{'merged'}  = 'yes' if $sp_details->{'refseq'} && ($job_data->{'core_type'} // '') eq 'merged';
  $vep_configs->{'gencode_basic'} = 'yes' if ($job_data->{'core_type'} // '') eq 'gencode_basic';
  $vep_configs->{'gencode_primary'} = 'yes' if ($job_data->{'core_type'} // '') eq 'gencode_primary';
  

  # return reference and uploaded alleles
  $vep_configs->{'show_ref_allele'} = 'yes';
  $vep_configs->{'uploaded_allele'} = 'yes';

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
      foreach my $pop_af (qw(af af_1kg af_gnomade af_gnomadg)) {
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
  $job_data->{$_} and $vep_configs->{$_} = $job_data->{$_} for qw(numbers canonical domains biotype symbol transcript_version ccds protein uniprot hgvs coding_only all_refseq tsl mane appris failed distance mirna);

  $vep_configs->{distance} = 0 if($job_data->{distance} eq '0' || $job_data->{distance} eq "");

  # check for incompatibilities
  if ($vep_configs->{'most_severe'} || $vep_configs->{'summary'}) {
    delete $vep_configs->{$_} for(qw(coding_only protein symbol sift polyphen ccds canonical numbers domains biotype tsl appris mane));
  }

  # plugins
  $vep_configs->{plugin} = $self->_configure_plugins($job_data);

  # custom annotation
  $vep_configs->{custom} = $self->_configure_custom_annotations($job_data);

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
  
  my $spliceai_file;
  
  foreach my $pl_key(grep {$_ =~ /^plugin\_/ && $job_data->{$_} eq $_} keys %$job_data) {
    
    $pl_key =~ s/^plugin\_//;
    my $plugin = $plugin_config{$pl_key};
    next unless $plugin;
    next if $plugin->{species} && !grep(/^$job_data->{'species'}$/i, @{$plugin->{species}});
    
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
        # SpliceAI plugin
        # check which snv file the user selected
        # file type is under 'plugin_SpliceAI_file_type'
        # snv_ensembl: file from Ensembl
        # snv: file from SpliceAI
        if($pl_key eq 'SpliceAI') {
          my $file_selected = $job_data->{'plugin_SpliceAI_file_type'};

          if($file_selected eq 'snv_ensembl' && $param_clone =~ /^snv_ensembl=/) {
            my $param_aux = $param_clone;
            $param_aux =~ s/snv_ensembl=//;
            # store the file that has been select by the user
            $spliceai_file = $param_aux;
          }
        }

        # CADD plugin
        if ($pl_key eq 'CADD'){
          my $file_selected = $job_data->{'plugin_CADD_file_type'};

          # check if species is pig and only add pig SNV file if that is the case
          if($file_selected eq 'snv' && $job_data->{'species'} eq "Sus_scrofa"){
            next unless $param_clone =~ /^snv_pig=/;

            my $param_aux = $param_clone;
            $param_aux =~ s/snv_pig=//;
            $param_clone = 'snv=' . $param_aux;
          } 
          # Only add appropriate files based on selected option otherwise
          elsif ($file_selected eq 'snv') {
            next unless $param_clone =~ /^snv=/;
          }
          elsif ($file_selected eq 'indels') {
            next unless $param_clone =~ /^indels=/;
          }
          elsif ($file_selected eq 'snv_indels') {
            next unless ($param_clone =~ /^snv=/ || $param_clone =~ /^indels=/);
          }
          elsif ($file_selected eq 'sv') {
            next unless $param_clone =~ /^sv=/;
          }
        }

        push @params, $param_clone;
      }
    }
    
    # If user selected file from Ensembl then $spliceai_file is defined
    # param 'snv' has to be updated to point to Ensembl's file
    # 'snv' and 'indel' are the parameters used by the plugin
    if(defined $spliceai_file) {
      my @new_params;
      foreach my $spliceai_param (@params) {
        if($spliceai_param =~ /^snv=/) {
          push @new_params, 'snv=' . $spliceai_file;
        }
        else {
          push @new_params, $spliceai_param;
        }
      }
      @params = @new_params;
    }
    
    push @active_plugins, join(",", ($pl_key, @params));
  }
  
  return \@active_plugins;
}

sub _configure_custom_annotations {
  my $self = shift;
  my $job_data = shift;
  
  # get custom annotation config into a hash keyed on key
  my $cu = $self->hub->species_defs->multi_val('ENSEMBL_VEP_CUSTOM_CONFIG');
  return [] unless $cu;
  my %custom_config = map {$_->{id} => $_} @{$cu || []};
  
  my @active_custom_ann = ();
  
  foreach my $cu_key(grep {$_ =~ /^custom\_/ && $job_data->{$_} eq $_} keys %$job_data) {
    
    $cu_key =~ s/^custom\_//;
    my $custom_ann = $custom_config{$cu_key};
    next unless $custom_ann;
    next if $custom_ann->{species} && !grep(/^$job_data->{'species'}$/, map { ucfirst $_ } @{ref $custom_ann->{species} eq 'ARRAY' ? $custom_ann->{species} : [$custom_ann->{species}]});

    my $params = $custom_ann->{params};

    # in VEP CLI custom annotation short_name is optional but here we make it mandatory 
    next unless ($params->{file} && $params->{format} && $params->{short_name});

    $params->{file} = $self->hub->species_defs->DATAFILE_BASE_PATH . $params->{file}; 
    $params->{type} ||= "overlap";
    $params->{fields} = join("%", @{$params->{fields}}) if ($params->{fields} && ref $params->{fields} eq 'ARRAY');
    $params->{coords} = $params->{coords} == 1 ? "1" : "0";

    my @custom_args;
    for (qw/file format short_name type fields coords/) {
      push (@custom_args, $_."=".$params->{$_}) if $params->{$_};
    }

    push @active_custom_ann, join(",", @custom_args);
  }
  
  return \@active_custom_ann;
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
    'regulatory'  => $db_config->{'DATABASE_FUNCGEN'}{'tables'}{'regulatory_build'}{'analyses'}{'Regulatory_Build'}->{'count'},
    'refseq'      => $db_config->{'DATABASE_OTHERFEATURES'} && $sd->get_config($species, 'VEP_REFSEQ')
  };
}

1;

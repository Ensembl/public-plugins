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

package EnsEMBL::Web::RunnableDB::VR;

### Hive Process RunnableDB for VR

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_append_contents);
use Bio::EnsEMBL::VEP::VariantRecoder;
use Bio::EnsEMBL::VEP::Utils qw(get_version_data);
use FileHandle;

sub fetch_input {
  my $self = shift;

  # required params
  $self->param_required($_) for qw(work_dir config job_id);
}

sub run {
  my $self = shift;

  my $work_dir        = $self->param('work_dir');
  my $config          = $self->param('config');
  my $options         = $self->param('script_options') || {};

  $options->{$_}  = sprintf '%s/%s', $work_dir, delete $config->{$_} for qw(input_file output_file);
  $options->{$_}  = $config->{$_} eq 'yes' ? 1 : $config->{$_} for grep { defined $config->{$_} && $config->{$_} ne 'no' } keys %$config;
  $options->{output_file} = $work_dir . '/vr_output.json'; 

  # Header contains: allele, input and the fields
  my $result_headers = $config->{'result_headers'};
  my @fields = @$result_headers;
  # Remove allele and input from list - remove vcf_string (in case it's there)
  for my $i (reverse 0..$#fields) {
    if ( $fields[$i] =~ /allele/ || $fields[$i] =~ /input/ || $fields[$i] =~ /vcf_string/) {
        splice(@fields, $i, 1, ());
    }
  }

  # Add vcf_string to the fields - need vcf_string to be able to download a VCF file
  $options->{'vcf_string'} = 1;

  $options->{'fields'} = join(',', @fields);

  # set reconnect_when_lost()
  my $reconnect_when_lost_bak = $self->dbc->reconnect_when_lost;
  $self->dbc->reconnect_when_lost(1);

  # create a Variant Recoder runner and run the job
  my $runner = Bio::EnsEMBL::VEP::VariantRecoder->new($options);
  my $results = $runner->recode_all;

  my $version_data = get_version_data();
  my $version = $version_data->{'ensembl-vep'}->{'release'};

  # Description of each output field
  # to be writen in the output files
  my %field_description;
  $field_description{'HGVSg'} = 'HGVS Genomic';
  $field_description{'HGVSc'} = 'HGVS Transcript';
  $field_description{'HGVSp'} = 'HGVS Protein';
  $field_description{'SPDI'} = 'Genomic SPDI notation. NCBI variation notation described as Sequence Position Deletion Insertion';
  $field_description{'VARID'} = 'Variant identifier is the ID of variants present in the Ensembl Variation database that are co-located with input';
  $field_description{'VCF'} = 'VCF string';
  $field_description{'Variant_synonyms'} = 'Extra known synonyms for co-located variants';
  $field_description{'MANE_Select'} = 'MANE Select (Matched Annotation from NCBI and EMBL-EBI) Transcripts';

  my @vcf_result;
  # Write VCF output header
  push @vcf_result, "##fileformat=VCFv4.2";
  push @vcf_result, "##Variant Recoder";
  push @vcf_result, "##API version $version";
  push @vcf_result, "##INFO=<ID=HGVSg,Number=.,Type=String,Description=\"". $field_description{'HGVSg'} ."\">";
  push @vcf_result, "##INFO=<ID=HGVSc,Number=.,Type=String,Description=\"". $field_description{'HGVSc'} ."\">";
  push @vcf_result, "##INFO=<ID=HGVSp,Number=.,Type=String,Description=\"". $field_description{'HGVSp'} ."\">";
  push @vcf_result, "##INFO=<ID=SPDI,Number=.,Type=String,Description=\"". $field_description{'HGVSg'} ."\>";
  push @vcf_result, "##INFO=<ID=VARID,Number=.,Type=String,Description=\"". $field_description{'VARID'} ."\">";
  push @vcf_result, "##INFO=<ID=VCF,Number=.,Type=String,Description=\"". $field_description{'VCF'} ."\">";
  push @vcf_result, "##INFO=<ID=Variant_synonyms,Number=.,Type=String,Description=\"". $field_description{'Variant_synonyms'} ."\">";
  push @vcf_result, "##INFO=<ID=MANE_Select,Number=.,Type=String,Description=\"". $field_description{'MANE_Select'} ."\">";
  push @vcf_result, "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO";

  # Stored output to be printed in TXT file
  my @print_output = ();
  push @print_output, "## Variant Recoder";
  push @print_output, "## API version $version";
  push @print_output, "## Column descriptions:";
  push @print_output, "## HGVSg: " . $field_description{'HGVSg'};
  push @print_output, "## HGVSc: " . $field_description{'HGVSc'};
  push @print_output, "## HGVSp: " . $field_description{'HGVSp'};
  push @print_output, "## SPDI: " . $field_description{'SPDI'};
  push @print_output, "## VARID: ". $field_description{'VARID'};
  push @print_output, "## VCF: ". $field_description{'VCF'};
  push @print_output, "## Variant_synonyms: ". $field_description{'Variant_synonyms'};
  push @print_output, "## MANE_Select: ". $field_description{'MANE_Select'};
  # Prepare header for TXT output file
  my $print_output_header = "#Uploaded_variant\tAllele";

  my $i = 0;

  foreach my $result_hash (@$results) {
    my @keys = keys %{$result_hash};
    foreach my $allele (@keys) {
      my $vcf_variant_info = '';
      my @synonyms_result;

      # When a variant doesn't have an ouput, one of the alleles is the warning message.
      # Skip these alleles
      # Example: 'A' => {}, 'warnings' => {}
      next if($allele eq 'warnings');

      my $allele_result = $result_hash->{$allele};

      my $print_input = $allele_result->{'input'}."\t".$allele;

      if($config->{'hgvsg'} eq 'yes') {
        if($allele_result->{'hgvsg'}) {
          my $join_result = join(', ', @{$allele_result->{'hgvsg'}});
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tHGVSg";
          # VCF
          $join_result =~ s/ //g;
          $vcf_variant_info .= "HGVSg=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'hgvsc'} eq 'yes') {
        if($allele_result->{'hgvsc'}) {
          my $join_result = join(', ', @{$allele_result->{'hgvsc'}});
          # Write header (txt file)
          $print_output_header .= "\tHGVSc";
          $print_input = $print_input."\t".$join_result;
          # VCF
          $join_result =~ s/ //g;
          $vcf_variant_info .= "HGVSc=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'hgvsp'} eq 'yes') {
        if($allele_result->{'hgvsp'}) {
          my $join_result = join(', ', @{$allele_result->{'hgvsp'}});
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tHGVSp";
          # VCF
          $join_result =~ s/ //g;
          $vcf_variant_info .= "HGVSp=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'spdi'} eq 'yes') {
        if($allele_result->{'spdi'}) {
          my $join_result = join(', ', @{$allele_result->{'spdi'}});
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tSPDI";
          # VCF
          $join_result =~ s/ //g;
          $vcf_variant_info .= "SPDI=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'id'} eq 'yes') {
        if($allele_result->{'id'}) {
         my $join_result = join(', ', @{$allele_result->{'id'}});
         $print_input = $print_input."\t".$join_result;
         # Write header (txt file)
         $print_output_header .= "\tVARID";
         # VCF
         $join_result =~ s/ //g;
         $vcf_variant_info .= "VARID=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'var_synonyms'} eq 'yes') {
        if($allele_result->{'var_synonyms'}) {
         my $join_result = join(', ', @{$allele_result->{'var_synonyms'}});
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tVariant_synonyms";
          # Variation synonyms
          $join_result =~ s/ //g;
          $vcf_variant_info .= "Variant_synonyms=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      if($config->{'mane_select'} eq 'yes') {
        if($allele_result->{'mane_select'}) {
          foreach my $hash (@{$allele_result->{'mane_select'}}) {
            my $hash_result = $hash->{'hgvsg'} . ";" . $hash->{'hgvsc'} . ";" . $hash->{'hgvsp'};
            push @synonyms_result, $hash_result;
          }
          my $join_result = join(', ', @synonyms_result);
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tMANE_Select";
          # Variation synonyms
          $join_result =~ s/ //g;
          $join_result =~ s/;/,/g;
          $vcf_variant_info .= "MANE_Select=$join_result;";
        }
        else {
          $print_input = $print_input."\t-";
        }
      }
      # ADD NEW OPTIONS HERE

      # vcf_string always runs because we need to know the VCF to be able to write and download a VCF file
      # this check should always be the last check
        if($allele_result->{'vcf_string'}) {
          my $join_result = join(', ', @{$allele_result->{'vcf_string'}});
          $print_input = $print_input."\t".$join_result;
          # Write header (txt file)
          $print_output_header .= "\tVCF";
          # VCF
          $vcf_variant_info .= "VCF=";

          foreach my $result (@{$allele_result->{'vcf_string'}}) {
           my @result_split = split /-/, $result;
           my $vcf_variant = $result_split[0] . "\t" . $result_split[1] . "\t" . $allele_result->{'input'} . "\t" . $result_split[2] . "\t" . $result_split[3] . "\t.\t\.\t";
           if($vcf_variant_info eq '') {
             $vcf_variant .= ".";
           }
           else {
             $vcf_variant .= $vcf_variant_info . $result . ";";
           }
           # all the data that is going to be written in the VCF output is stored in $vcf_variant
           push @vcf_result, $vcf_variant;
          }
        }

      # Print header (txt file)
      if($i == 0) {
        push @print_output, $print_output_header;
      }
      push @print_output, $print_input;
    }
  $i += 1;
  }

  my $fh = FileHandle->new("$work_dir/output_test", 'w');
  # Write output - VCF format
  my $fh_vcf = FileHandle->new("$work_dir/vr_output.vcf", 'w');
  print $fh_vcf join("\n", @vcf_result);
  $fh_vcf->close();

  # Write output - TXT format
  my $fh = FileHandle->new("$work_dir/vr_output", 'w');
  print $fh join("\n", @print_output);
  $fh->close();

  # Write output - JSON format
  my $json = JSON->new;
  $json->pretty;
  file_append_contents($options->{output_file}, $json->encode($results));

  # restore reconnect_when_lost()
  $self->dbc->reconnect_when_lost($reconnect_when_lost_bak);

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');

  return 1;
}

1;

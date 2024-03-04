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

package EnsEMBL::Web::Object::LD;

use strict;
use warnings;

use HTML::Entities  qw(encode_entities);

use EnsEMBL::Web::TmpFile::ToolsOutput;
use EnsEMBL::Web::TmpFile::VcfTabix;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use Bio::EnsEMBL::Variation::Utils::Constants;
use Bio::EnsEMBL::Variation::Utils::VariationEffect;

use parent qw(EnsEMBL::Web::Object::Tools);

sub tab_caption {
  ## @override
  return 'LD';
}

sub valid_species {
  ## @override
  my $self = shift;
  return $self->hub->species_defs->reference_species($self->SUPER::valid_species(@_));
}

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self        = shift;
  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket   or return [];
  my $job         = shift @{ $ticket->job || [] } or return [];
  my $job_data    = $job->job_data->raw;
  my $input_file  = sprintf '%s/%s', $job->job_dir, $job_data->{'input_file'};

  if (-T $input_file && $input_file !~ /\.gz$/ && $input_file !~ /\.zip$/) { # TODO - check if the file is binary!
    if (-s $input_file <= 1024) {
      $job_data->{"text"} = file_get_contents($input_file);
    } else {
      $job_data->{'input_file_type'}  = 'text';
      $job_data->{'input_file_url'}   = $self->download_url({'input' => 1});
    }
  } else {
    $job_data->{'input_file_type'} = 'binary';
  }

  return [ $job_data ];
}

sub result_files {
  ## Gets the result stats and ouput files
  my $self = shift;
  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->dispatcher_data->{'config'};
    my @output_file_names = @{$job_config->{'output_file_names'}};
    my $job_dir     = $job->job_dir;
    my $output_file = $job_config->{'output_file'} || 'no output file defined';
    foreach my $output_file (@output_file_names) {
      $self->{'_results_files'}->{$output_file} = EnsEMBL::Web::TmpFile::ToolsOutput->new('filename' => "$job_dir/$output_file");
    } 
  }

  return $self->{'_results_files'};
}

sub handle_download {
  my ($self, $r) = @_;

  my $hub = $self->hub;
  my $job = $self->get_requested_job;

  my $output_file = $hub->param('output_file');
  my $file      = $self->result_files->{$output_file};
  my $filename  = $job->ticket->ticket_name . $file;

  $r->headers_out->add('Content-Type'         => 'text/plain');
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s', $output_file);
 
  return $r->sendfile(join('/', $job->job_dir, $output_file));
}

sub get_form_details {
  my $self = shift;
  if(!exists($self->{_form_details})) {
    # core form
    $self->{_form_details} = {
      ld_calculation => {
        'label' => 'Choose calculation',
        'helptip' => 
          '<b>Compute pairwise LD values in a region, compute all pairwise LD values for list of variants, or </b>'.
          '<b>compute all LD values for a given variant and all variants that are within a given window size.</b>',
        'values' => [
          { 'value' => 'region', 'caption' => 'LD in a given region' },
          { 'value' => 'pairwise', 'caption' => 'LD for a given list of variants' },
          { 'value' => 'center', 'caption' => 'LD for a given variant within a defined window size' },
        ],
      },
      r2_threshold => {
        'label' => 'Threshold for r<sup>2</sup>',
        'helptip' => 'Only include variants whose r<sup>2</sup> value is greater than or equal to the given value. r<sup>2</sup> needs to be in the range of 0.0 and 1.0.',
        'value' => '0.0', 
      },
      d_prime_threshold => {
        'label' => "Threshold for D'",
        'helptip' => 'Only include variants whose D\' value is greater than or equal to the given value. D\' needs to be in the range of 0.0 and 1.0.',
        'value' => '0.0',
      },
      window_size => {
        'label' => 'Window size',
        'helptip' => 'Only compute LD between the input variant and all variants within the given window size. The maximum allowed size is 500000bp.',
        'value' => '200000',
      },
    };
  }
  return $self->{_form_details};
}

# for each species with a variation database return all populations with sufficient amounts of sample genotype data stored in VCF files
# for human we have genotypes from the 1000 Genomes Project
sub LD_populations {
  my $self = shift;
  my $hub = $self->hub;
  my $sd = $hub->species_defs;
  for ($self->valid_species) {
    my $db_config = $sd->get_config($_, 'databases');
    if ($db_config->{'DATABASE_VARIATION'}) {
      if (! defined $self->{'_population_list'}->{$_}) {
        my $adaptor = $self->hub->get_adaptor('get_PopulationAdaptor', 'variation', $_);
        my $ld_populations = $adaptor->fetch_all_LD_Populations;
        foreach my $ld_population (@$ld_populations) {
          my $name = $ld_population->name;
          push @{$self->{'_population_list'}->{$_}}, {'value' => $name, 'caption' => $name};
        }
      }
    }
  }
  return $self->{'_population_list'};
}

sub species_list {
  ## Returns a list of species with VEP specific info
  ## @return Arrayref of hashes with each hash having species specific info
  my $self = shift;
  if (!$self->{'_species_list'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;
    my @species;

    for ($self->valid_species) {
      my $db_config = $sd->get_config($_, 'databases');
      if ($db_config->{'DATABASE_VARIATION'}) {
        my $adaptor = $self->hub->get_adaptor('get_PopulationAdaptor', 'variation', $_);
        my $ld_populations = $adaptor->fetch_all_LD_Populations;
        next unless (scalar @$ld_populations > 0);
        # if has enough sample genotype data for LD computation
        
        my $sample_data   = $sd->get_config($_, 'SAMPLE_DATA');
        my $example_data = {};
        for (grep m/^LD/, keys %$sample_data) {
          $example_data->{lc s/^LD\_//r} = $sample_data->{$_};
        }

        push @species, {
          'value'       => $_,
          'caption'     => $sd->species_label($_, 1),
          'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME') // undef,
          'example'     => $example_data,
        };
      }
    }
    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }
  return $self->{'_species_list'};
}

1;

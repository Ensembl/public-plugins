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

package EnsEMBL::Web::Object::VR;

use strict;
use warnings;

use HTML::Entities  qw(encode_entities);

use EnsEMBL::Web::TmpFile::ToolsOutput;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use Bio::EnsEMBL::Variation::Utils::Constants;
use Bio::EnsEMBL::Variation::Utils::VariationEffect;

use parent qw(EnsEMBL::Web::Object::Tools);

sub tab_caption {
  ## @override
  return 'VR';
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
  ## Gets the ouput files
  my $self = shift;

  if (!$self->{'_results_files'}) {
    my $ticket      = $self->get_requested_ticket or return;
    my $job         = $ticket->job->[0] or return;
    my $job_config  = $job->dispatcher_data->{'config'};
    my $job_dir     = $job->job_dir;

    $self->{'_results_files'} = {
      'output_file' => EnsEMBL::Web::TmpFile::ToolsOutput->new('filename' => "$job_dir/$job_config->{'output_file'}")
    };
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

    $self->{_form_details} = {
        id => {
          'label'   => 'Variant identifier',
          'helptip' => 'Variants present in the Ensembl Variation database that are co-located with input',
        },
        spdi => {
          'label'   => 'SPDI',
          'helptip' => 'Genomic SPDI notation: NCBI variation notation described as Sequence Position Deletion Insertion (https://www.ncbi.nlm.nih.gov/variation/notation/)',
        },
        hgvsg => {
          'label'   => 'HGVS Genomic',
          'helptip' => 'HGVS genomic sequence name',
        },
        hgvsc => {
          'label'   => 'HGVS Transcript',
          'helptip' => 'HGVS coding sequence name',
        },
        hgvsp => {
          'label'   => 'HGVS Protein',
          'helptip' => 'HGVS protein sequence name',
        },
        vcf_string => {
          'label'   => 'VCF format',
          'helptip' => 'Position based name',
        },
        var_synonyms => {
          'label'   => 'Variant synonyms',
          'helptip' => 'Extra known synonyms for co-located variants',
        },
        mane_select => {
          'label'   => 'MANE Select',
          'helptip' => 'MANE Select (Matched Annotation from NCBI and EMBL-EBI) Transcript',
        },
    };
  }

  return $self->{_form_details};
}

sub species_list {
  ## Returns a list of species with VR specific info
  ## @return Arrayref of hashes with each hash having species specific info
  my $self = shift;

  if (!$self->{'_species_list'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;

    my @species;

    for ($self->valid_species) {

      # Ignore any species with VEP disabled
      next if ($sd->get_config($_, 'VEP_DISABLED'));

      my $db_config = $sd->get_config($_, 'databases');

      # example data for each species
      my $sample_data   = $sd->get_config($_, 'SAMPLE_DATA');
      my $example_data  = {};
      # on ini files the VR data has key "VR_"; VEP data has "VEP_"
      # VR can use some VEP examples such as VEP_ID, VEP_SPDI and VEP_HGVS
      for (grep m/^(VR|VEP)/, keys %$sample_data) {
        # VEP_HGVS is the same as VR_HGVSC
        # use VEP_HGVS instead
        if($_ eq 'VEP_HGVS') {
          $example_data->{hgvsc} = $sample_data->{$_};
        }
        else {
          $example_data->{lc s/^(VR|VEP)\_//r} = $sample_data->{$_};
        }
      }

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'variation'   => $db_config->{'DATABASE_VARIATION'} // undef,
        'refseq'      => $db_config->{'DATABASE_OTHERFEATURES'} && $sd->get_config($_, 'VEP_REFSEQ') // undef,
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME') // undef,
        'example'     => $example_data,
      };
    }

    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }

  return $self->{'_species_list'};
}

1;

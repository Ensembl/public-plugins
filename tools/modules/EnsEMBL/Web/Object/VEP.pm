=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::VEP;

use strict;
use warnings;

use HTML::Entities  qw(encode_entities);

use EnsEMBL::Web::TmpFile::ToolsOutput;
use EnsEMBL::Web::TmpFile::VcfTabix;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use Bio::EnsEMBL::Variation::Utils::Constants;

use parent qw(EnsEMBL::Web::Object::Tools);

sub tab_caption {
  ## @override
  return 'VEP';
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
    my $job_dir     = $job->job_dir;

    $self->{'_results_files'} = {
      'output_file' => EnsEMBL::Web::TmpFile::VcfTabix->new('filename' => "$job_dir/$job_config->{'output_file'}"),
      'stats_file'  => EnsEMBL::Web::TmpFile::ToolsOutput->new('filename' => "$job_dir/$job_config->{'stats_file'}")
    };
  }

  return $self->{'_results_files'};
}

sub get_all_variants_in_slice_region {
  ## Gets all the result variants for the given job in the given slice region
  ## @param Job object
  ## @param Slice object
  ## @return Array of result data hashrefs
  my ($self, $job, $slice) = @_;

  my $ticket_name = $job->ticket->ticket_name;
  my $job_id      = $job->job_id;
  my $s_name      = $slice->seq_region_name;
  my $s_start     = $slice->start;
  my $s_end       = $slice->end;

  my @variants;

  for ($job->result) {

    my $var   = $_->result_data->raw;
    my $chr   = $var->{'chr'};
    my $start = $var->{'start'};
    my $end   = $var->{'end'};

    next unless $s_name eq $chr && (
      $start >= $s_start && $end <= $s_end ||
      $start < $s_start && $end <= $s_end && $end > $s_start ||
      $start >= $s_start && $start <= $s_end && $end > $s_end ||
      $start < $s_start && $end > $s_end && $start < $s_end
    );

    $var->{'tl'} = $self->create_url_param({'ticket_name' => $ticket_name, 'job_id' => $job_id, 'result_id' => $_->result_id});

    push @variants, $var;

  };

  return \@variants;
}

sub handle_download {
  my ($self, $r) = @_;

  my $hub = $self->hub;
  my $job = $self->get_requested_job;

  # if downloading the input file
  if ($hub->param('input')) {

    my $filename  = $job->job_data->{'input_file'};
    my $content   = file_get_contents(join('/', $job->job_dir, $filename), sub { s/\R/\r\n/r });

    $r->headers_out->add('Content-Type'         => 'text/plain');
    $r->headers_out->add('Content-Length'       => length $content);
    $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s', $filename);

    print $content;

  # if downloading the result file in any specified format
  } else {

    my $format    = $hub->param('format')   || 'vcf';
    my $location  = $hub->param('location') || '';
    my $filter    = $hub->param('filter')   || '';
    my $file      = $self->result_files->{'output_file'};
    my $filename  = join('.', $job->ticket->ticket_name, $location || (), $filter || (), $format eq 'txt' ? () : $format, $format eq 'vcf' ? '' : 'txt') =~ s/\s+/\_/gr;

    $r->headers_out->add('Content-Type'         => 'text/plain');
    $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s', $filename);

    $file->content_iterate({'format' => $format, 'location' => $location, 'filter' => $filter}, sub {
      print "$_\r\n" for @_;
      $r->rflush;
    });
  }
}

sub get_form_details {
  my $self = shift;

  if(!exists($self->{_form_details})) {

    # core form
    $self->{_form_details} = {
      core_type => {
        'label'   => 'Transcript database to use',
        'helptip' =>
          '<b>Gencode basic:</b> a subset of the Ensembl transcript set; partial and other low quality transcripts are removed<br/>'.
          '<b>RefSeq:</b> aligned transcripts from NCBI RefSeq',
        'values'  => [
          { 'value' => 'core',          'caption' => 'Ensembl transcripts'            },
          { 'value' => 'gencode_basic', 'caption' => 'Gencode basic transcripts'      },
          { 'value' => 'refseq',        'caption' => 'RefSeq transcripts'             },
          { 'value' => 'merged',        'caption' => 'Ensembl and RefSeq transcripts' }
        ],
      },

      all_refseq => {
        'label'   => 'Include additional EST and CCDS transcripts',
        'helptip' => 'The RefSeq transcript set also contains aligned EST and CCDS transcripts that are excluded by default',
      },

      # identifiers section
      symbol => {
        'label'   => 'Gene symbol',
        'helptip' => 'Report the gene symbol (e.g. HGNC)',
      },

      ccds => {
        'label'   => 'CCDS',
        'helptip' => 'Report the Consensus CDS identifier where applicable',
      },

      protein => {
        'label'   => 'Protein',
        'helptip' => 'Report the Ensembl protein identifier',
      },

      uniprot => {
        'label'   => 'Uniprot',
        'helptip' => 'Report identifiers from SWISSPROT, TrEMBL and UniParc',
      },

      hgvs => {
        'label'   => 'HGVS',
        'helptip' => 'Report HGVSc (coding sequence) and HGVSp (protein) notations for your variants',
      },

      # frequency data
      check_existing => {
        'label'   => 'Find co-located known variants',
        'helptip' => "Report known variants from the Ensembl Variation database that are co-located with input. Use 'compare alleles' to only report co-located variants where none of the input variant's alleles are novel",
        'values'  => [
          { 'value'     => 'no',      'caption' => 'No'                       },
          { 'value'     => 'yes',     'caption' => 'Yes'                      },
          { 'value'     => 'allele',  'caption' => 'Yes and compare alleles'  }
        ]
      },

      gmaf => {
        'label'   => '1000 Genomes global minor allele frequency',
        'helptip' => 'Report the minor allele frequency for the combined 1000 Genomes Project phase 1 population',
      },

      maf_1kg => {
        'label'   => '1000 Genomes continental allele frequencies',
        'helptip' => 'Report allele frequencies for the combined 1000 Genomes Project phase 1 continental populations - AFR (African), AMR (American), EAS (East Asian), EUR (European) and SAS (South Asian)',
      },

      maf_esp => {
        'label'   => 'ESP allele frequencies',
        'helptip' => 'Report allele frequencies for the NHLBI Exome Sequencing Project populations - AA (African American) and EA (European American)',
      },

      maf_exac => {
        'label'   => 'ExAC allele frequencies',
        'helptip' => 'Report allele frequencies from the Exome Aggregation Consortium',
      },

      pubmed => {
        'label'   => 'PubMed IDs for citations of co-located variants',
        'helptip' => 'Report the PubMed IDs of any publications that cite this variant',
      },

      failed => {
        'label'   => 'Include flagged variants',
        'helptip' => 'The Ensembl QC pipeline flags some variants as failed; by default these are not included when searching for known variants',
      },

      biotype => {
        'label'   => 'Transcript biotype',
        'helptip' => 'Report the biotype of overlapped transcripts, e.g. protein_coding, miRNA, psuedogene',
      },

      domains => {
        'label'   => 'Protein domains',
        'helptip' => 'Report overlapping protein domains from Pfam, Prosite and InterPro',
      },

      numbers => {
        'label'   => 'Exon and intron numbers',
        'helptip' => 'For variants that fall in the exon or intron, report the exon or intron number as NUMBER / TOTAL',
      },

      tsl => {
        'label'   => 'Transcript support level',
        'helptip' => encode_entities($self->hub->glossary_lookup->{'TSL'} || ''),
      },

      appris => {
        'label'   => 'APPRIS',
        'helptip' => encode_entities($self->hub->glossary_lookup->{'APPRIS'} || ''),
      },

      canonical => {
        'label'   => 'Identify canonical transcripts',
        'helptip' => encode_entities($self->hub->glossary_lookup->{'Canonical transcript'} || ''),
      },

      sift => {
        'label'   => 'SIFT',
        'helptip' => 'Report SIFT scores and/or predictions for missense variants. SIFT is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'values'  => [
          { 'value'     => 'no',    'caption' => 'No'                   },
          { 'value'     => 'both',  'caption' => 'Prediction and score' },
          { 'value'     => 'pred',  'caption' => 'Prediction only'      },
          { 'value'     => 'score', 'caption' => 'Score only'           }
        ]
      },

      polyphen => {
        'label'   => 'PolyPhen',
        'helptip' => 'Report PolyPhen scores and/or predictions for missense variants. PolyPhen is an algorithm to predict whether an amino acid substitution is likely to affect protein function',
        'values'  => [
          { 'value'     => 'no',    'caption' => 'No'                   },
          { 'value'     => 'both',  'caption' => 'Prediction and score' },
          { 'value'     => 'pred',  'caption' => 'Prediction only'      },
          { 'value'     => 'score', 'caption' => 'Score only'           }
        ]
      },

      regulatory => {
        'label'   => 'Get regulatory region consequences',
        'helptip' => 'Get consequences for variants that overlap regulatory features and transcription factor binding motifs',
        'values'  => [
          { 'value'       => 'no',   'caption' => 'No'                          },
          { 'value'       => 'reg',  'caption' => 'Yes'                         },
          { 'value'       => 'cell', 'caption' => 'Yes and limit by cell type'  }
        ]
      },

      cell_type => {
        'label'   => 'Limit to cell type(s)',
        'helptip' => 'Select one or more cell types to limit regulatory feature results to. Hold Ctrl (Windows) or Cmd (Mac) to select multiple entries.',
      },

      frequency => {
        'label'   => 'Filter by frequency',
        'helptip' => 'Exclude common variants to remove input variants that overlap with known variants that have a minor allele frequency greater than 1% in the 1000 Genomes Phase 1 combined population. Use advanced filtering to change the population, frequency threshold and other parameters',
        'values'  => [
          { 'value' => 'no',        'caption' => 'No filtering'             },
          { 'value' => 'common',    'caption' => 'Exclude common variants'  },
          { 'value' => 'advanced',  'caption' => 'Advanced filtering'       }
        ]
      },

      freq_filter => {
        'values' => [
          { 'value' => 'exclude', 'caption' => 'Exclude'      },
          { 'value' => 'include', 'caption' => 'Include only' }
        ]
      },

      freq_gt_lt => {
        'values' => [
          { 'value' => 'gt', 'caption' => 'variants with MAF greater than' },
          { 'value' => 'lt', 'caption' => 'variants with MAF less than'    },
        ]
      },

      freq_pop => {
        'values' => [
          { 'value' => '1kg_all', 'caption' => 'in 1000 genomes (1KG) combined population' },
          { 'value' => '1kg_afr', 'caption' => 'in 1KG African combined population'        },
          { 'value' => '1kg_amr', 'caption' => 'in 1KG American combined population'       },
          { 'value' => '1kg_eas', 'caption' => 'in 1KG East Asian combined population'     },
          { 'value' => '1kg_eur', 'caption' => 'in 1KG European combined population'       },
          { 'value' => '1kg_sas', 'caption' => 'in 1KG South Asian combined population'    },
          { 'value' => 'esp_aa',  'caption' => 'in ESP African-American population'        },
          { 'value' => 'esp_ea',  'caption' => 'in ESP European-American population'       },
        ],
      },

      coding_only => {
        'label'   => 'Return results for variants in coding regions only',
        'helptip' => 'Exclude results in intronic and intergenic regions',
      },

      summary => {
        'label'   => 'Restrict results',
        'helptip' => 'Restrict results by severity of consequence; note that consequence ranks are determined subjectively by Ensembl',
        'values'  => [
          { 'value' => 'no',          'caption' => 'Show all results' },
          { 'value' => 'pick',        'caption' => 'Show one selected consequence per variant'},
          { 'value' => 'pick_allele', 'caption' => 'Show one selected consequence per variant allele'},
          { 'value' => 'per_gene',    'caption' => 'Show one selected consequence per gene' },
          { 'value' => 'summary',     'caption' => 'Show only list of consequences per variant' },
          { 'value' => 'most_severe', 'caption' => 'Show most severe consequence per variant' },
        ]
      },
    };


    # add plugin stuff
    my $sd  = $self->hub->species_defs;
    if(my $pl = $sd->multi_val('ENSEMBL_VEP_PLUGIN_CONFIG')) {

      foreach my $plugin(@{$pl->{plugins}}) {

        # each plugin form element has "plugin_" prepended to it
        $self->{_form_details}->{'plugin_'.$plugin->{key}} = {
          label => $plugin->{label} || $plugin->{key},   # plugins may not have a label
          helptip => $plugin->{helptip},
        };

        # add plugin-specific form elements
        # e.g. option selector for dbNSFP
        foreach my $form_el(@{$plugin->{form} || []}) {
          $self->{_form_details}->{'plugin_'.$plugin->{key}.'_'.$form_el->{name}} = {
            label => ($plugin->{label} || $plugin->{key}).' '.($form_el->{label} || $form_el->{name}),   # prepend label with plugin label
            helptip => $form_el->{helptip},
            values => $form_el->{values}
          };
        }
      }
    }
  }

  return $self->{_form_details};
}

sub get_consequences_data {
  ## Gets overlap consequences information needed to render preview
  ## @return Hashref with keys as consequence types
  my $self  = shift;
  my $hub   = $self->hub;
  my $cm    = $hub->colourmap;
  my $sd    = $hub->species_defs;

  my %cons = map {$_->{'SO_term'} => {
    'description' => $_->{'description'},
    'rank'        => $_->{'rank'},
    'colour'      => $cm->hex_by_name($sd->colour('variation')->{lc $_->{'SO_term'}}->{'default'})
  }} values %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;

  return \%cons;
}

sub species_list {
  ## Returns a list of species with VEP specific info
  ## @return Arrayref of hashes with each hash having species specific info
  my $self = shift;

  if (!$self->{'_species_list'}) {
    my $hub     = $self->hub;
    my $sd      = $hub->species_defs;

    # at the moment only human, chicken and mouse have RefSeqs in their otherfeatures DB
    # there's no config for this currently so species are listed manually
    my %refseq  = map { $_ => 1 } qw(
      Anolis_carolinensis
      Bos_taurus
      Canis_familiaris
      Ciona_intestinalis
      Danio_rerio
      Felis_catus
      Gallus_gallus
      Homo_sapiens
      Mus_musculus
      Oryctolagus_cuniculus
      Ovis_aries
      Pan_troglodytes
      Papio_anubis
      Rattus_norvegicus
      Sus_scrofa
    );

    my @species;

    for ($sd->tools_valid_species) {

      my $db_config = $sd->get_config($_, 'databases');

      # example data for each species
      my $sample_data   = $sd->get_config($_, 'SAMPLE_DATA');
      my $example_data  = {};
      for (grep m/^VEP/, keys %$sample_data) {
        $example_data->{lc s/^VEP\_//r} = $sample_data->{$_};
      }

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'variation'   => $db_config->{'DATABASE_VARIATION'},
        'refseq'      => $refseq{$_} && $db_config->{'DATABASE_OTHERFEATURES'},
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME'),
        'regulatory'  => $sd->get_config($_, 'REGULATORY_BUILD'),
        'example'     => $example_data,
      };
    }

    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }

  return $self->{'_species_list'};
}

1;

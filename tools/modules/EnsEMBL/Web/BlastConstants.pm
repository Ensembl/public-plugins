=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::BlastConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK    = qw(MAX_SEQUENCE_LENGTH MAX_NUM_SEQUENCES DNA_THRESHOLD_PERCENT SEQUENCE_VALID_CHARS BLAST_KARYOTYPE_POINTER CONFIGURATION_FIELDS CONFIGURATION_DEFAULTS CONFIGURATION_SETS);
our %EXPORT_TAGS  = ('all' => [ @EXPORT_OK ]);

sub MAX_SEQUENCE_LENGTH   { 200000              }
sub MAX_NUM_SEQUENCES     { 30                  }
sub DNA_THRESHOLD_PERCENT { 85                  }
sub SEQUENCE_VALID_CHARS  { 'A-Za-z\-\.\*\?=~'  }

sub BLAST_KARYOTYPE_POINTER {
  return {
    'style'             => 'rharrow',
    'colour'            => 'gradient',
    'high_score_style'  => 'outbox',
    'gradient'          => [qw(10 gold orange chocolate firebrick darkred)],
    'gradient_others'   => [qw(10 gray60 gray50 gray40 gray30 gray20)]
  };
}

sub CONFIGURATION_FIELDS {
  return [
    'general'             => [

      'max_target_seqs'     => {
        'type'                => 'dropdown',
        'label'               => 'Maximum number of hits to report',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(10 50 100 250 500 1000 5000) ]
      },

      'culling_limit'       => {
        'type'                => 'dropdown',
        'label'               => 'Culling limit',
        'helptip'             => 'This will throw away hits that are enveloped by at least this many higher-scoring hits',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 1..10,15,20,999 ]
      },

      'evalue'              => {
        'type'                => 'dropdown',
        'label'               => 'Maximum E-value for reported alignments',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(1e-200 1e-100 1e-50 1e-10 1e-5 1e-4 1e-3 1e-2 1e-1 1.0 10 100 1000 10000 100000) ]
      },

      'word_size'           => {
        'type'                => 'dropdown',
        'label'               => 'Word size for seeding alignments',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 2..15 ]
      }
    ],

    'scoring'             => [

      'gapopen'             => {
        'type'                => 'dropdown',
        'label'               => 'Penalty for opening a gap',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 1..15 ]
      },

      'gapextend'           => {
        'type'                => 'dropdown',
        'label'               =>  'Penalty for extending a gap',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 1..15 ]
      },

      'ungapped'            => {
        'type'                => 'checklist',
        'label'               => 'Disallow gaps in Alignment',
        'values'              => [ { 'value' => '1' } ],
        'commandline_type'    => 'flag',
      },

      'reward'              => {
        'type'                => 'dropdown',
        'label'               => 'Match score',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 1..5 ]
      },

      'penalty'             => {
        'type'                => 'dropdown',
        'label'               => 'Mismatch score',
        'values'              => [ reverse map { 'value' => $_, 'caption' => $_ }, -5..-1 ]
      },

      'matrix'              => {
        'type'                => 'dropdown',
        'label'               => 'Scoring matrix to use',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(PAM30 PAM70 PAM250 BLOSUM45 BLOSUM50 BLOSUM62 BLOSUM80 BLOSUM90) ]
      },

      'comp_based_stats'    => {
        'type'                => 'dropdown',
        'label'               => 'Compositional adjustments',
        'values'              => [
                                  { 'value' => '0', 'caption' => 'No adjustment' },
                                  { 'value' => '1', 'caption' => 'Composition-based statistics' },
                                  { 'value' => '2', 'caption' => 'Conditional compositional score matrix adjustment' },
                                  { 'value' => '3', 'caption' => 'Universal compositional score matrix adjustment' },
        ],
      },

      'threshold'           => {
        'type'                => 'dropdown',
        'label'               => 'Minimium score to add a word to the BLAST lookup table',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, 11..16,20,999 ]
      },

    ],

    'filters_and_masking'  => [

      'dust'                => {
        'type'                => 'checklist',
        'label'               => 'Filter low complexity regions',
        'values'              => [ { 'value' => '1' } ],
        'commandline_values'  => {'1' => 'yes', '' => 'no'}
      },

      'seg'                 => {
        'type'                => 'checklist',
        'label'               => 'Filter low complexity regions',
        'values'              => [ { 'value' => '1' } ],
        'commandline_values'  => {'1' => 'yes', '' => 'no'}
      },

      'repeat_mask'         => {
        'type'                => 'checklist',
        'label'               => 'Filter query sequences using RepeatMasker',
        'values'              => [ { 'value' => '1' } ]
      }

    ]

  ];
}

sub CONFIGURATION_DEFAULTS {
  return {

    'all'                     => {
      'evalue'                  => '1e-1',
      'max_target_seqs'         => '100',
    },

    'NCBIBLAST_BLASTN'        => {
      'word_size'               => '11',
      'reward'                  => '2',
      'penalty'                 => '-3',
      'ungapped'                => '0',
      'gapopen'                 => '5',
      'gapextend'               => '2',
      'dust'                    => '1',
      'repeat_mask'             => '1',
      'culling_limit'           => '5',
    },

    'NCBIBLAST_BLASTP'        => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'gapopen'                 => '11',
      'gapextend'               => '1',
      'threshold'               => '11',
      'comp_based_stats'        => '2',
      'seg'                     => '1',
      'culling_limit'           => '5',
    },

    'NCBIBLAST_BLASTX'        => {
      'word_size'               => '3',
      'matrix'                  => 'BLOSUM62',
      'gapopen'                 => '11',
      'gapextend'               => '1',
      'threshold'               => '11',
      'seg'                     => '1',
      'repeat_mask'             => '1',
      'culling_limit'           => '5',
    },

    'NCBIBLAST_TBLASTN'       => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'gapopen'                 => '11',
      'gapextend'               => '1',
      'threshold'               => '13',
      'comp_based_stats'        => '2',
      'seg'                     => '1',
      'culling_limit'           => '5',
    },

    'NCBIBLAST_TBLASTX'       => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'threshold'               => '13',
      'seg'                     => '1',
      'culling_limit'           => '5',
    }
  };
}

sub CONFIGURATION_SETS {

  my $sets = {
    'dna'         => {
      'near'        => {
        'word_size'   => 15,
        'dust'        => 1,
        'evalue'      => 10,
        'reward'      => 1,
        'penalty'     => -3,
        'gapopen'     => 5,
        'gapextend'   => 2
      },
      'near_oligo'  => {
        'word_size'   => 7,
        'dust'        => 0,
        'evalue'      => 1000,
        'reward'      => 1,
        'penalty'     => -3,
        'gapopen'     => 5,
        'gapextend'   => 2
      },
      'normal'      => {
        'word_size'   => 11,
        'dust'        => 1,
        'evalue'      => 10,
        'reward'      => 1,
        'penalty'     => -3,
        'gapopen'     => 5,
        'gapextend'   => 2
      },
      'distant'     => {
        'word_size'   => 9,
        'dust'        => 1,
        'evalue'      => 10,
        'reward'      => 1,
        'penalty'     => -1,
        'gapopen'     => 2,
        'gapextend'   => 1
      },
    },
    'protein'     => {
      'near'        => {
        'matrix'      => 'BLOSUM90',
        'gapopen'     => 10,
        'gapextend'   => 1
      },
      'normal'      => {
        'matrix'      => 'BLOSUM62',
        'gapopen'     => 11,
        'gapextend'   => 1
      },
      'distant'     => {
        'matrix'      => 'BLOSUM45',
        'gapopen'     => 14,
        'gapextend'   => 2
      },
    }
  };

  return [
    { 'value' => 'near',        'caption' => 'Near match'},
    { 'value' => 'near_oligo',  'caption' => 'Short sequences'},
    { 'value' => 'normal',      'caption' => 'Normal', 'selected' => 'true'},
    { 'value' => 'distant',     'caption' => 'Distant homologies'}
  ], {
    'NCBIBLAST_BLASTN'        => $sets->{'dna'},
    'NCBIBLAST_BLASTP'        => $sets->{'protein'},
    'NCBIBLAST_BLASTX'        => $sets->{'protein'},
    'NCBIBLAST_TBLASTN'       => $sets->{'protein'},
    'NCBIBLAST_TBLASTX'       => $sets->{'protein'},
  };
}

1;

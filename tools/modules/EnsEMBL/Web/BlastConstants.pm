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

package EnsEMBL::Web::BlastConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK    = qw(MAX_SEQUENCE_LENGTH MAX_NUM_SEQUENCES DNA_THRESHOLD_PERCENT BLAST_KARYOTYPE_POINTER CONFIGURATION_FIELDS CONFIGURATION_DEFAULTS SEQUENCE_VALID_CHARS);
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
    'gradient'          => [qw(10 gold orange chocolate firebrick darkred)]
  };
}

sub CONFIGURATION_FIELDS {
  return [
    'general'             => [

      'max_target_seqs'     => {
        'type'                => 'dropdown',
        'label'               => 'Maximum number of hits to report',
        'values'              => [
                                  { 'value' => '10',    'caption' => '10' },
                                  { 'value' => '50',    'caption' => '50' },
                                  { 'value' => '100',   'caption' => '100' },
                                  { 'value' => '250',   'caption' => '250' },
                                  { 'value' => '500',   'caption' => '500' },
                                  { 'value' => '1000',  'caption' => '1000' },
                                  { 'value' => '5000',  'caption' => '5000' }
        ],
      },

      'culling_limit'       => {
        'type'                => 'dropdown',
        'label'               => 'Throw away hits that are enveloped by at least this many higher-scoring hits',
        'values'              => [
                                  { 'value' => '1',   'caption' => '1' },
                                  { 'value' => '2',   'caption' => '2' },
                                  { 'value' => '3',   'caption' => '3' },
                                  { 'value' => '4',   'caption' => '4' },
                                  { 'value' => '5',   'caption' => '5' },
                                  { 'value' => '7',   'caption' => '7' },
                                  { 'value' => '10',  'caption' => '10' },
                                  { 'value' => '15',  'caption' => '15' },
                                  { 'value' => '20',  'caption' => '20' },
                                  { 'value' => '999', 'caption' => '999' },
        ]
      },

      'evalue'              => {
        'type'                => 'dropdown',
        'label'               => 'Maximum E-value for reported alignments',
        'values'              => [
                                  { 'value' => '1e-200',  'caption' => '1e-200' },
                                  { 'value' => '1e-100',  'caption' => '1e-100' },
                                  { 'value' => '1e-50',   'caption' => '1e-50' },
                                  { 'value' => '1e-10',   'caption' => '1e-10' },
                                  { 'value' => '1e-5',    'caption' => '1e-5' },
                                  { 'value' => '1e-4',    'caption' => '1e-4' },
                                  { 'value' => '1e-3',    'caption' => '1e-3' },
                                  { 'value' => '1e-2',    'caption' => '1e-2' },
                                  { 'value' => '1e-1',    'caption' => '1e-1' },
                                  { 'value' => '1',       'caption' => '1.0' },
                                  { 'value' => '10',      'caption' => '10' },
                                  { 'value' => '100',     'caption' => '100' },
                                  { 'value' => '1000',    'caption' => '1000' },
        ]
      },

      'word_size'           => {
        'type'                => 'dropdown',
        'label'               => 'Word size for seeding alignments',
        'values'              => [
                                  { 'value' => '2',   'caption' => '2' },
                                  { 'value' => '3',   'caption' => '3' },
                                  { 'value' => '4',   'caption' => '4' },
                                  { 'value' => '6',   'caption' => '8' },
                                  { 'value' => '11',  'caption' => '11' },
                                  { 'value' => '15',  'caption' => '15' },
        ]
      }
    ],

    'scoring'             => [

      'gapopen'             => {
        'type'                => 'dropdown',
        'label'               => 'Penalty for opening a gap',
        'values'              => [
                                  { 'value' => '1',   'caption' => '1' },
                                  { 'value' => '2',   'caption' => '2' },
                                  { 'value' => '3',   'caption' => '3' },
                                  { 'value' => '4',   'caption' => '4' },
                                  { 'value' => '5',   'caption' => '5' },
                                  { 'value' => '6',   'caption' => '6' },
                                  { 'value' => '7',   'caption' => '7' },
                                  { 'value' => '8',   'caption' => '8' },
                                  { 'value' => '9',   'caption' => '9' },
                                  { 'value' => '10',  'caption' => '10' },
                                  { 'value' => '11',  'caption' => '11' },
                                  { 'value' => '12',  'caption' => '12' },
                                  { 'value' => '13',  'caption' => '13' },
                                  { 'value' => '14',  'caption' => '14' },
                                  { 'value' => '15',  'caption' => '15' },
        ],
      },

      'gapextend'           => {
        'type'                => 'dropdown',
        'label'               =>  'Penalty for extending a gap',
        'values'              => [
                                  { 'value' => '1',   'caption' => '1' },
                                  { 'value' => '2',   'caption' => '2' },
                                  { 'value' => '3',   'caption' => '3' },
                                  { 'value' => '5',   'caption' => '5' },
                                  { 'value' => '9',   'caption' => '9' },
                                  { 'value' => '10',  'caption' => '10' },
                                  { 'value' => '15',  'caption' => '15' },
        ],
      },

      'ungapped'            => {
        'type'                => 'checklist',
        'label'               => 'Allow gaps in Alignment',
        'values'              => [ { 'value' => '1' } ],
        'commandline_type'    => 'flag',
      },

      'reward'              => {
        'type'                => 'dropdown',
        'label'               => 'Match score',
        'values'              => [
                                  { 'value' => '1', 'caption' => '1' },
                                  { 'value' => '2', 'caption' => '2' },
                                  { 'value' => '3', 'caption' => '3' },
                                  { 'value' => '4', 'caption' => '4' },
                                  { 'value' => '5', 'caption' => '5' },
        ]
      },

      'penalty'             => {
        'type'                => 'dropdown',
        'label'               => 'Mismatch score',
        'values'              => [
                                  { 'value' => '-1', 'caption' => '-1' },
                                  { 'value' => '-2', 'caption' => '-2' },
                                  { 'value' => '-3', 'caption' => '-3' },
                                  { 'value' => '-4', 'caption' => '-4' },
                                  { 'value' => '-5', 'caption' => '-5' },
        ],
      },

      'matrix'              => {
        'type'                => 'dropdown',
        'label'               => 'Scoring matrix to use',
        'values'              => [
                                  { 'value' => 'PAM30',     'caption' => 'PAM30' },
                                  { 'value' => 'PAM70',     'caption' => 'PAM70' },
                                  { 'value' => 'PAM250',    'caption' => 'PAM250'},
                                  { 'value' => 'BLOSUM45',  'caption' => 'BLOSUM45' },
                                  { 'value' => 'BLOSUM50',  'caption' => 'BLOSUM50' },
                                  { 'value' => 'BLOSUM62',  'caption' => 'BLOSUM62' },
                                  { 'value' => 'BLOSUM80',  'caption' => 'BLOSUM80' },
                                  { 'value' => 'BLOSUM90',  'caption' => 'BLOSUM90' },
        ]
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
        'values'              => [
                                  { 'value' => '11',  'caption' => '11' },
                                  { 'value' => '12',  'caption' => '12' },
                                  { 'value' => '13',  'caption' => '13' },
                                  { 'value' => '14',  'caption' => '14' },
                                  { 'value' => '15',  'caption' => '15' },
                                  { 'value' => '16',  'caption' => '16' },
                                  { 'value' => '20',  'caption' => '20' },
                                  { 'value' => '999', 'caption' => '999' },
        ],
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
      'culling_limit'           => '5',
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
    },

    'NCBIBLAST_BLASTN-SHORT'  => {
      'word_size'               => '7',
      'reward'                  => '1',
      'penalty'                 => '-3',
      'ungapped'                => '0',
      'gapopen'                 => '5',
      'gapextend'               => '2',
      'dust'                    => '1',
      'repeat_mask'             => '1',
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
    },

    'NCBIBLAST_BLASTP-SHORT'  => {
      'word_size'               => '2',
      'ungapped'                => '0',
      'matrix'                  => 'PAM30',
      'gapopen'                 => '9',
      'gapextend'               => '1',
      'threshold'               => '16',
      'comp_based_stats'        => '0',
      'seg'                     => '1',
    },

    'NCBIBLAST_BLASTX'        => {
      'word_size'               => '3',
      'matrix'                  => 'BLOSUM62',
      'gapopen'                 => '11',
      'gapextend'               => '1',
      'threshold'               => '11',
      'seg'                     => '1',
      'repeat_mask'             => '1',
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
    },

    'NCBIBLAST_TBLASTX'       => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'threshold'               => '13',
      'seg'                     => '1',
    }
  };
}

1;

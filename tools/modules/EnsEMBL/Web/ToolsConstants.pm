package EnsEMBL::Web::ToolsConstants;

use strict;
use warnings;

sub BLAST_CONFIGURATION_OPTIONS {
  return (
    'general' => {

      'max_target_seqs' => {
        type    => 'dropdown',
        name    => 'max_target_seqs',
        label   => 'Maximum number of hits to report',
        values  => [    
          { value => '10',    caption => '10' },
          { value => '50',    caption => '50' },
          { value => '100',   caption => '100' },
          { value => '250',   caption => '250' },
          { value => '500',   caption => '500' },
          { value => '1000',  caption => '1000' },
          { value => '5000',  caption => '5000' }
        ],
        value => '100',
      }, 

      'culling_limit' => {
        type    => 'dropdown',
        name    => 'culling_limit',
        label   => 'Throw away hits that are enveloped by at least this many higher-scoring hits',
        values  => [
          { value => '1',   caption => '1' },
          { value => '2',   caption => '2' },
          { value => '3',   caption => '3' },
          { value => '4',   caption => '4' },
          { value => '5',   caption => '5' },
          { value => '7',   caption => '7' },
          { value => '10',  caption => '10' },
          { value => '15',  caption => '15' },
          { value => '20',  caption => '20' },
          { value => '999', caption => '999' },
        ]
      },

      'evalue' => {
        type    => 'dropdown',
        name    => 'evalue',
        label   => 'Maximum E-value for reported alignments',
        values  => [
          { value => '1e-200',  caption => '1e-200' },
          { value => '1e-100',  caption => '1e-100' },
          { value => '1e-50',   caption => '1e-50' },
          { value => '1e-10',   caption => '1e-10' },
          { value => '1e-5',    caption => '1e-5' },
          { value => '1e-4',    caption => '1e-4' },
          { value => '1e-3',    caption => '1e-3' },
          { value => '1e-2',    caption => '1e-2' },
          { value => '1e-1',    caption => '1e-1' },
          { value => '1',       caption => '1.0' },
          { value => '10',      caption => '10' },
          { value => '100',     caption => '100' },
          { value => '1000',    caption => '1000' },
        ],
        value => 10,
      }, 

      'word_size' => {
        type    => 'dropdown',
        name    => 'word_size',
        label   => 'Word size for seeding alignments',
        values  => [
          { value => '2',   caption => '2' },
          { value => '3',   caption => '3' },
          { value => '4',   caption => '4' },
          { value => '6',   caption => '8' },
          { value => '11',  caption => '11' },
          { value => '15',  caption => '15' },
        ],        
      },

      'query_loc' => {
        type    => 'string',
        name    => 'query_loc',
        label   => 'Location on the query sequence',
        size    => '30',
      },
      
    },

    'scoring' => {

      'gapopen' => {
        type    => 'dropdown',
        name    => 'gapopen',
        label   => 'Penalty for opening a gap',
        values  => [
          { value => '1',   caption => '1' },
          { value => '2',   caption => '2' },
          { value => '3',   caption => '3' },
          { value => '4',   caption => '4' },
          { value => '5',   caption => '5' },
          { value => '6',   caption => '6' },
          { value => '7',   caption => '7' },
          { value => '8',   caption => '8' },
          { value => '9',   caption => '9' },
          { value => '10',  caption => '10' },
          { value => '11',  caption => '11' },
          { value => '12',  caption => '12' },
          { value => '13',  caption => '13' },
          { value => '14',  caption => '14' },
          { value => '15',  caption => '15' },
        ],
      },

      'gapextend' => {
        type    => 'dropdown',
        name    => 'gapextend',
        label   =>  'Penalty for extending a gap',
        values  => [
          { value => '1',   caption => '1' },
          { value => '2',   caption => '2' },
          { value => '3',   caption => '3' },
          { value => '5',   caption => '5' },
          { value => '9',   caption => '9' },
          { value => '10',  caption => '10' },
          { value => '15',  caption => '15' },
        ],
      },

      'ungapped'  => {
        type      => 'checkbox',
        name      => 'ungapped',
        label     => 'Allow gaps in Alignment',
        selected  => 1
      },

      'reward'  => {
        type    => 'dropdown',
        name    => 'reward',
        label   => 'Match score',
        values  => [
          { value => '1', caption => '1' },
          { value => '2', caption => '2' },
          { value => '3', caption => '3' },
          { value => '4', caption => '4' },
          { value => '5', caption => '5' },
        ]
      },

      'penalty' => {
        type    => 'dropdown',
        name    => 'penalty',
        label   => 'Mismatch score',
        values  => [
          { value => '-1', caption => '-1' },
          { value => '-2', caption => '-2' },
          { value => '-3', caption => '-3' },
          { value => '-4', caption => '-4' },
          { value => '-5', caption => '-5' },
        ],
      },
  
      'matrix'  => {
        type    => 'dropdown',
        name    => 'matrix',
        label   => 'Scoring matrix to use',
        values  => [
          { value => 'PAM30',     caption => 'PAM30' },
          { value => 'PAM70',     caption => 'PAM70' },
          { value => 'PAM250',    caption => 'PAM250'},
          { value => 'BLOSUM45',  caption => 'BLOSUM45' },
          { value => 'BLOSUM50',  caption => 'BLOSUM50' },
          { value => 'BLOSUM62',  caption => 'BLOSUM62' },
          { value => 'BLOSUM80',  caption => 'BLOSUM80' },
          { value => 'BLOSUM90',  caption => 'BLOSUM90' },
        ]
      },

      'comp_based_stats' => {
        type    => 'dropdown',
        name    => 'comp_based_stats',
        label   => 'Compositional adjustments',
        values  => [
          { value => '0', caption => 'No adjustment' },
          { value => '1', caption => 'Composition-based statistics' },
          { value => '2', caption => 'Conditional compositional score matrix adjustment' },
          { value => '3', caption => 'Universal compositional score matrix adjustment' }, 
        ], 
      },
      
      'threshold' => {
        type    => 'dropdown',
        name    => 'threshold',
        label   => 'Minimium score to add a word to the BLAST lookup table', 
        values  => [
          { value => '11',  caption => '11' },
          { value => '12',  caption => '12' },
          { value => '13',  caption => '13' },
          { value => '14',  caption => '14' },
          { value => '15',  caption => '15' },
          { value => '16',  caption => '16' },
          { value => '20',  caption => '20' },
          { value => '999', caption => '999' },
        ],
      },

    },

    'filters_and_masking' => {
    
      'dust' => {
        type      => 'checkbox',
        name      => 'dust',
        label     => 'Filter low complexity regions',
        selected  => 1 
      },

      'seg' => {
        type      => 'checkbox',
        name      => 'seg',
        label     => 'Filter low complexity regions',
        selected  => 1
      },

      'repeat_mask' => {
        type      => 'checkbox',
        name      => 'repeat_mask',
        label     => 'Filter query sequences using RepeatMasker',
        selected  => 0
      }

    },

    # what is available for each search method + default values 
    'options_and_defaults' => {

      'general' => [
        [ 'evalue', {'all' => '1e-1'}],
        [ 'max_target_seqs', { 'all' => 100 }],
        [ 'culling_limit', { 'all' => 5 }],
        [ 'word_size', { 
            'blastn'        => '11',
            'blastn-short'  => '7',
            'blastp'        => '3',
            'blastp-short'  => '2',
            'blastx'        => '3',
            'tblastn'       => '3',
            'tblastx'       => '3',
        }],
        [ 'query_loc', { 'all' => 'START-END' }],
      ],      

      'scoring' => [
        [ 'reward', { 'blastn' => '2','blastn-short' => '1'}],
        [ 'penalty', { 'blastn' => '-3', 'blastn-short'  => '-3'}],
        [ 'ungapped', {
            'blastn'        => 'no', 
            'blastn-short'  => 'no',
            'blastp'        => 'no',
            'blastp-short'  => 'no',
            'tblastn'       => 'no',
            'tblastx'       => 'no',
        }],
        [ 'matrix', {
            'blastp'        => 'BLOSUM62',
            'blastp-short'  => 'PAM30',
            'blastx'        =>  'BLOSUM62',
            'tblastn'       => 'BLOSUM62',
            'tblastx'       =>  'BLOSUM62',
        }],
        [ 'gapopen', {
            'blastn'        => '5',
            'blastn-short'  => '5',
            'blastp'        => '11',
            'blastp-short'  =>  '9',
            'blastx'        =>  '11',
            'tblastn'       =>  '11',
        }],
        [ 'gapextend', { 
            'blastn'        => '2',
            'blastn-short'  => '2',
            'blastp'        => '1',
            'blastp-short'  => '1',
            'blastx'        => '1',
            'tblastn'       => '1',
        }],
        [ 'threshold', {
            'blastp'        => '11',
            'blastp-short'  => '16',
            'blastx'        => '11',
            'tblastn'       => '13',
            'tblastx'       => '13'
        }],
        [ 'comp_based_stats', {
            'blastp'        => '2',
            'blastp-short'  => '0',
            'tblastn'       => '2',   
        }],
      ],

      'filters_and_masking' => [
        [ 'dust', { 'blastn' => 'yes', 'blastn-short' => 'yes'}],
        [ 'seg', { 
            'blastp'        => 'yes', 
            'blastp-short'  => 'yes', 
            'blastx'        => 'yes', 
            'tblastn'       => 'yes', 
            'tblastx'       => 'yes'
        }],
        ['repeat_mask', {
            'blastn'        => 'yes',
            'blastn-short'  => 'yes',
            'blastx'        => 'yes',
        }],
      ],
    },
  );
}

sub KARYOTYPE_POINTER_DEFAULTS {
  return  (
    'Blast'           => [ 'rharrow', 'gradient', [qw(10 gold orange chocolate firebrick darkred)]],
  );
} 

1;

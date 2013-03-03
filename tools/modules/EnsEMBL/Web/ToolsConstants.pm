package EnsEMBL::Web::ToolsConstants;

use strict;
use warnings;
no warnings 'uninitialized';

sub BLAST_CONFIGURATION_OPTIONS {
  return (
    'general' => {

      'max_target_seqs' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'max_target_seqs',
        label   => 'Maximum number of hits to report',
        values  => [    
          { value => '10',    name => '10' },
          { value => '50',    name => '50' },
          { value => '100',   name => '100' },
          { value => '250',   name => '250' },
          { value => '500',   name => '500' },
          { value => '1000',  name => '1000' },
          { value => '5000',  name => '5000' }
        ],
        value => '100',
      }, 

      'evalue' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'evalue',
        label   => 'Maximum E-value for reported alignments',
        values  => [
          { value => '1e-200',  name => '1e-200' },
          { value => '1e-100',  name => '1e-100' },
          { value => '1e-50',   name => '1e-50' },
          { value => '1e-10',   name => '1e-10' },
          { value => '1e-5',    name => '1e-5' },
          { value => '1e-4',    name => '1e-4' },
          { value => '1e-3',    name => '1e-3' },
          { value => '1e-2',    name => '1e-2' },
          { value => '1e-1',    name => '1e-1' },
          { value => '1',       name => '1.0' },
          { value => '10',      name => '10' },
          { value => '100',     name => '100' },
          { value => '1000',    name => '1000' },
        ],
        value => 10,
      }, 

      'word_size' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'word_size',
        label   => 'Word size for seeding alignments',
        values  => [
          { value => '2',   name => '2' },
          { value => '3',   name => '3' },
          { value => '4',   name => '4' },
          { value => '6',   name => '8' },
          { value => '11',  name => '11' },
          { value => '15',  name => '15' },
        ],        
      },

      'query_loc' => {
        type    => 'String',
        name    => 'query_loc',
        label   => 'Location on the query sequence',
        size    => '30',
      },
      
    },

    'scoring' => {

      'gapopen' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'gapopen',
        label   => 'Penalty for opening a gap',
        values  => [
          { value => '1',   name => '1' },
          { value => '2',   name => '2' },
          { value => '3',   name => '3' },
          { value => '4',   name => '4' },
          { value => '5',   name => '5' },
          { value => '6',   name => '6' },
          { value => '7',   name => '7' },
          { value => '8',   name => '8' },
          { value => '9',   name => '9' },
          { value => '10',  name => '10' },
          { value => '11',  name => '11' },
          { value => '12',  name => '12' },
          { value => '13',  name => '13' },
          { value => '14',  name => '14' },
          { value => '15',  name => '15' },
        ],
      },

      'gapextend' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'gapextend',
        label   =>  'Penalty for extending a gap',
        values  => [
          { value => '1',   name => '1' },
          { value => '2',   name => '2' },
          { value => '3',   name => '3' },
          { value => '5',   name => '5' },
          { value => '9',   name => '9' },
          { value => '10',  name => '10' },
          { value => '15',  name => '15' },
        ],
      },

      'ungapped'  => {
        type      => 'CheckBox',
        name      => 'ungapped',
        label     => 'Allow gaps in Alignment',
        selected  => 1
      },

      'reward'  => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'reward',
        label   => 'Match score',
        values  => [
          { value => '1', name => '1' },
          { value => '2', name => '2' },
          { value => '3', name => '3' },
          { value => '4', name => '4' },
          { value => '5', name => '5' },
        ]
      },

      'penalty' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'penalty',
        label   => 'Mismatch score',
        values  => [
          { value => '-1', name => '-1' },
          { value => '-2', name => '-2' },
          { value => '-3', name => '-3' },
          { value => '-4', name => '-4' },
          { value => '-5', name => '-5' },
        ],
      },
  
      'matrix'  => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'matrix',
        label   => 'Scoring matrix to use',
        values  => [
          { value => 'PAM30', name  => 'PAM30' },
          { value => 'PAM70', name  => 'PAM70' },
          { value => 'PAM250', name => 'PAM250'},
          { value => 'BLOSUM45', name => 'BLOSUM45' },
          { value => 'BLOSUM50', name => 'BLOSUM50' },
          { value => 'BLOSUM62', name => 'BLOSUM62' },
          { value => 'BLOSUM80', name => 'BLOSUM80' },
          { value => 'BLOSUM90', name => 'BLOSUM90' },
        ]
      },

      'comp_based_stats' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'comp_based_stats',
        label   => 'Compositional adjustments',
        values  => [
          { value => '0', name => 'No adjustment' },
          { value => '1', name => 'Composition-based statistics' },
          { value => '2', name => 'Conditional compositional score matrix adjustment' },
          { value => '3', name => 'Universal compositional score matrix adjustment' }, 
        ], 
      },
      
      'threshold' => {
        type    => 'DropDown',
        select  => 'select',
        name    => 'threshold',
        label   => 'Minimium score to add a word to the BLAST lookup table', 
        values  => [
          { value => '11', name => '11' },
          { value => '12', name => '12' },
          { value => '13', name => '13' },
          { value => '14', name => '14' },
          { value => '15', name => '15' },
          { value => '16', name => '16' },
          { value => '20', name => '20' },
          { value => '999', name => '999' },
        ],
      },

    },

    'filters_and_masking' => {
    
      'dust' => {
        type      => 'CheckBox',
        name      => 'dust',
        label     => 'Filter low complexity regions',
        selected  => 0 
      },

      'seg' => {
        type      => 'CheckBox',
        name      => 'seg',
        label     => 'Filter low complexity regions',
        selected  => 0
      },

      'repeat_mask' => {
        type      => 'CheckBox',
        name      => 'repeat_mask',
        label     => 'Filter query sequences using RepeatMasker',
        selected  => 0
      }

    },

    # what is available for each search method + default values 
    'options_and_defaults' => {

      'general' => [
        [ 'evalue', {'all' => '10'}],
        [ 'max_target_seqs', { 'all' => 100 }],
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

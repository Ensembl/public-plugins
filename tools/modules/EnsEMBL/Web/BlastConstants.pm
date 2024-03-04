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

package EnsEMBL::Web::BlastConstants;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK    = qw(MAX_SEQUENCE_LENGTH MAX_NUM_SEQUENCES DNA_THRESHOLD_PERCENT SEQUENCE_VALID_CHARS BLAST_TRACK_PATTERN BLAST_KARYOTYPE_POINTER CONFIGURATION_FIELDS CONFIGURATION_DEFAULTS CONFIGURATION_SETS);
our %EXPORT_TAGS  = ('all' => [ @EXPORT_OK ]);

sub MAX_SEQUENCE_LENGTH   { 200000                }
sub MAX_NUM_SEQUENCES     { 30                    }
sub DNA_THRESHOLD_PERCENT { 85                    }
sub SEQUENCE_VALID_CHARS  { 'A-Za-z\-\.\*\?=~'    }
sub BLAST_TRACK_PATTERN   { 'pin_ne|background1'  }

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
  
  my $matrix = {
      "BLOSUM45"  => ["14n2", "13n3", "12n3", "11n3", "10n3", "16n2", "15n2", "13n2", "12n2", "19n1", "18n1", "17n1", "16n1", "-1n-1", "-1n2", "14n-1", "16n-1", "15n-1", "13n-1",              "12n-1"  ],
      "BLOSUM50"  => ["13n2", "13n3", "12n3", "11n3", "10n3", "9n3", "16n2", "15n2", "14n2", "12n2", "19n1", "18n1", "17n1", "16n1", "15n1", "-1n-1", "-1n2", "-1n3", "16n-1",              "15n-1", "14n-1", "12n-1"],
      "BLOSUM62"  => ["11n1", "10n2", "9n2", "8n2", "7n2", "6n2", "16n2", "15n2", "13n2", "12n2", "13n1", "12n1", "10n1", "19n1", "-1n-1", "-1n1", "13n-1", "12n-1", "10n-1", "19n-1"               ],
      "BLOSUM80"  => ["10n1", "25n2", "13n2", "9n2", "8n2", "7n2", "6n2", "11n1", "9n1", "-1n-1", "-1n1", "10n-1", "11n-1", "9n-1"],
      "BLOSUM90"  => ["10n1", "7n2", "6n2", "5n2", "9n1", "8n1", "-1n-1", "-1n1", "10n-1", "9n-1", "8n-1"],
      "PAM30"     => ["9n1", "7n2", "6n2", "5n2", "10n1", "8n1", "-1n-1", "-1n1", "9n-1", "10n-1", "8n-1"],
      "PAM70"     => ["10n1", "8n2", "7n2", "6n2", "11n1", "9n1", "-1n-1", "10n-1", "-1n1", "9n-1"],
      "PAM250"    => ["14n2", "15n3", "14n3", "13n3", "12n3", "11n3", "17n2", "16n2", "15n2", "13n2", "21n1", "20n1", "19n1", "18n1", "17n1", "-1n-1", "14n-1", "-1n2", "-1n3",             "17n-1","16n-1", "15n-1", "13n-1"]  
  };  

  my $reward_hash = {
    "1_5"    =>  "1,-5",
    "1_4"    =>  "1,-4",
    "2_7"    =>  "2,-7",
    "1_3"    =>  "1,-3",
    "2_5"    =>  "2,-5",
    "1_2"    =>  "1,-2",
    "2_3"    =>  "2,-3",
    "3_4"    =>  "3,-4",
    "4_5"    =>  "4,-5",
    "1_1"    =>  "1,-1",
    "3_2"    =>  "3,-2",
    "5_4"    =>  "5,-4"
  };

  my $reward = {
      "1_5" => ["3n3"],
      "1_4" => ["1n2", "0n2", "2n1", "1n1"],
      "2_7" => ["2n4", "0n4", "4n2", "2n2"],
      "1_3" => ["2n2", "1n2", "0n2", "2n1", "1n1"],
      "2_5" => ["2n4", "0n4", "4n2", "2n2"],
      "1_2" => ["2n2", "1n2", "0n2", "3n1", "2n1", "1n1"],
      "2_3" => ["4n4", "2n4", "0n4", "3n3", "6n2", "5n2", "4n2", "2n2"],
      "3_4" => ["6n3", "5n3", "4n3", "6n2", "5n2", "4n2"],
      "4_5" => ["6n5", "5n5", "4n5", "3n5"],
      "1_1" => ["3n2", "2n2", "1n2", "0n2", "4n1", "3n1", "2n1"],
      "3_2" => ["5n5"],
      "5_4" => ["10n6", "8n6"]
  };   
  
  my $scoring = [       
    'ungapped'            => {
      'type'                => 'checklist',
      'label'               => 'Disallow gaps in Alignment',
      'values'              => [ { 'value' => '1' } ],
      'commandline_type'    => 'flag',
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
    }
  ];
  
  unshift(@$scoring,   
    'matrix'              => {
        'type'                => 'dropdown',
        'label'               => 'Scoring matrix to use',
        'class'               => '_stt',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, sort keys %$matrix ]
    },

    'score'              => {
      'type'                => 'dropdown',
      'label'               => 'Match/Mismatch scores',
      'class'               => '_stt',
      'values'              => [ map { 'value' => $_, 'caption' => $reward_hash->{$_}}, sort keys %$reward ]
    },
    
    #this the same dropdown as Gap penalties for other BLAST but this is only used for BLASTN without scoring matrix
    "gap_dna"           => {                                
       'label'              => 'Gap penalties',
       'elements'           =>  [map {{'name' => "gap_dna",  element_class => 'gapopen-options', 'group' => "$_", 'class', => "_stt_$_", 'type' => 'dropdown', 'values'  => [ map {'value' => $_, 'caption' => "Opening: ".(split(/n/,$_))[0].", Extension: ".(split(/n/,$_))[1] }, @{$reward->{$_}}] }}  keys %$reward]
    },
    
    "gappenalty"          => {                                
       'label'              => 'Gap penalties',
       'elements'           =>  [map {{'name' => "gappenalty_$_",  element_class => 'gapopen-options', 'group' => "$_", 'class', => "_stt_$_", 'type' => 'dropdown', 'values'  => [ map {'value' => $_, 'caption' => "Opening: ".(split(/n/,$_))[0].", Extension: ".(split(/n/,$_))[1] }, @{$matrix->{$_}} ] }}  keys %$matrix]
    }
  ); 
    
  return [
    'general'             => {
      'caption'             => '',
      'fields'              => [

        'max_target_seqs'     => {
          'type'                => 'dropdown',
          'label'               => 'Maximum number of hits to report',
          'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(10 50 100 250 500 1000 5000) ]
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
        },

        'max_hsps'                => {
          'type'                => 'dropdown',
          'label'               => 'Maximum HSPs per hit',
          'value'               => '100',
          'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(1 2 5 10 50 100) ]
        }
      ]
    },

    'scoring'             => {
      'caption'             => '',
      'fields'              => $scoring
    },

    'filters_and_masking' => {
      'caption'             => '',
      'fields'              => [

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
          'values'              => [ { 'value' => '1' } ],
          'commandline_values'  => {'1' => 'yes', '' => 'no'}
	}

      ]

    }
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
      'score'                  => '1_2',      
      'ungapped'                => '0',
      'gap_dna'                 => '5n2',
      'dust'                    => '1',
      'repeat_mask'             => '1',
      'max_hsps'                    => '100'
    },

    'NCBIBLAST_BLASTP'        => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'gappenalty'             => '11n1',
      'threshold'               => '11',
      'comp_based_stats'        => '2',
      'seg'                     => '1',
      'max_hsps'                    => '100'
    },

    'NCBIBLAST_BLASTX'        => {
      'word_size'               => '3',
      'matrix'                  => 'BLOSUM62',
      'gappenalty'              => '11n1',
      'threshold'               => '11',
      'seg'                     => '1',
      'repeat_mask'             => '1',
      'max_hsps'                    => '100'
    },

    'NCBIBLAST_TBLASTN'       => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'gappenalty'              => '11n1',
      'threshold'               => '13',
      'comp_based_stats'        => '2',
      'seg'                     => '1',
      'max_hsps'                    => '100'
    },

    'NCBIBLAST_TBLASTX'       => {
      'word_size'               => '3',
      'ungapped'                => '0',
      'matrix'                  => 'BLOSUM62',
      'threshold'               => '13',
      'seg'                     => '1',
      'max_hsps'                    => '100'
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
        'score'       => "1_3",
        'gap_dna'     => "5n2"
      },
      'near_oligo'  => {
        'word_size'   => 7,
        'dust'        => 0,
        'evalue'      => 1000,
        'score'       => "1_3",
        'gap_dna'     => "5n2"
      },
      'normal'      => {
        'word_size'   => 11,
        'dust'        => 1,
        'evalue'      => 10,
        'score'       => "1_3",
        'gap_dna'     => "5n2"
      },
      'distant'     => {
        'word_size'   => 9,
        'dust'        => 1,
        'evalue'      => 10,
        'score'       => "1_1",
        'gap_dna'     => "2n1"
      },
    },
    'protein'     => {
      'near'        => {
        'matrix'          => 'BLOSUM90',
        'gappenalty'      => '10n1',
      },
      'normal'      => {
        'matrix'          => 'BLOSUM62',
        'gappenalty'      => '11n1',
      },
      'distant'     => {
        'matrix'          => 'BLOSUM45',
        'gappenalty'      => '14n2',
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

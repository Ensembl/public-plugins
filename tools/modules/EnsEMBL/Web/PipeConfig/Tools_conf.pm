package EnsEMBL::Web::PipeConfig::Tools_conf;

use strict;
use warnings;

use EnsEMBL::Web::SpeciesDefs;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

our $species_defs = EnsEMBL::Web::SpeciesDefs->new;

sub default_options { #add in ticket db config here somewhere
  my ($self) = @_;
  return {
    'ensembl_cvs_root_dir' => $species_defs->ENSEMBL_SERVERROOT,  

    'pipeline_name' =>  'ensembl_blast',  
    'hive_use_triggers'     => 0,

    'pipeline_db'   => {  
      -host   =>  $species_defs->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
      -port   =>  $species_defs->multidb->{'DATABASE_WEB_HIVE'}{'PORT'}, 
      -user   =>  $species_defs->DATABASE_WRITE_USER,
      -pass   =>  $species_defs->DATABASE_WRITE_PASS,
      -dbname =>  $species_defs->multidb->{'DATABASE_WEB_HIVE'}{'NAME'},
    },     

    'ticket_db' =>{
      -host   =>  $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
      -port   =>  $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
      -user   =>  $species_defs->DATABASE_WRITE_USER,
      -pass   =>  $species_defs->DATABASE_WRITE_PASS,
      -dbname =>  $species_defs->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
    },  

    'blast_options' => {
    },

    'work_dir'                => $species_defs->ENSEMBL_TMP_DIR_BLAST,
    'blast_bin_dir'           => $species_defs->ENSEMBL_BLAST_BIN_PATH,
    'blast_matrix'            => $species_defs->ENSEMBL_BLAST_MATRIX,      
    'blast_index_files'       => $species_defs->ENSEMBL_BLAST_DATA_PATH,  
    'blast_dna_index_files'   => $species_defs->ENSEMBL_BLAST_DATA_PATH_DNA,
    'repeat_mask_bin_dir'     => $species_defs->ENSEMBL_REPEATMASK_BIN_PATH  
  };
}

sub pipeline_analyses {
  my ($self) = @_;
  return [
    { -logic_name => 'Blast', #one for each blast?
      -module     =>  'EnsEMBL::Web::RunnableDB::Blast::Submit', #RunnableDB name,
      -parameters => { #global params for a runnable
          'ticket_db'             => $self->o('ticket_db'),
          'blast_options'         => $self->o('blast_options'),
          'work_dir'              => $self->o('work_dir'),
          'blast_bin_dir'         => $self->o('blast_bin_dir'),          
          'blast_matrix'          => $self->o('blast_matrix'),
          'blast_index_files'     => $self->o('blast_index_files'),
          'blast_dna_index_files' => $self->o('blast_dna_index_files'),
          'ensembl_cvs_root_dir'  => $self->o('ensembl_cvs_root_dir'),
          'repeatmask_bin_dir'    => $self->o('repeat_mask_bin_dir'),
        },
      -hive_capacity => 2, # workers that run at a time per analysis 
   },
    { -logic_name =>'BLAT', # one of these per analysis
      -module     =>'', #.... 
    },
  ];
    
}
1;

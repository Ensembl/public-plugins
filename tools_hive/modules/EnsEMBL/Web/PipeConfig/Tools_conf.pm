=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::PipeConfig::Tools_conf;

use strict; 
use warnings;

use DBI;
use EnsEMBL::Web::SpeciesDefs;

use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

use parent qw(Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf);

sub new {
  ## @override
  ## @constructor
  ## Adds some extra info to the object
  my $self  = shift->SUPER::new(@_);
  my $sd    = $self->{'_species_defs'} = EnsEMBL::Web::SpeciesDefs->new;

  $self->{'_available_tools'} = [ map dynamic_require($_), (
    $sd->ENSEMBL_BLAST_ENABLED ? ('EnsEMBL::Web::ToolsPipeConfig::Blast', 'EnsEMBL::Web::ToolsPipeConfig::Blat') : (),
    $sd->ENSEMBL_VEP_ENABLED   ? 'EnsEMBL::Web::ToolsPipeConfig::VEP' : (),
    $sd->ENSEMBL_AC_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::AssemblyConverter' : (),
    $sd->ENSEMBL_IDM_ENABLED   ? 'EnsEMBL::Web::ToolsPipeConfig::IDMapper' : (),
    $sd->ENSEMBL_FC_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::FileChameleon' : (),
    $sd->ENSEMBL_AF_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::AlleleFrequency' : (),
    $sd->ENSEMBL_VP_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::VcftoPed' : (),
    $sd->ENSEMBL_DS_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::DataSlicer' : (),
    $sd->ENSEMBL_VPF_ENABLED   ? 'EnsEMBL::Web::ToolsPipeConfig::VariationPattern' : (),
    $sd->ENSEMBL_LD_ENABLED    ? 'EnsEMBL::Web::ToolsPipeConfig::LD' : (),
  ) ];

  return $self;
}

sub species_defs {
  ## @return Species defs object
  return shift->{'_species_defs'};
}

sub available_tools {
  ## Gets a list of all the tools conf constant packages
  ## @return Arrayref of class names
  return @{shift->{'_available_tools'}};
}

sub default_options {
  ## @override
  my $self  = shift;
  my $sd    = $self->species_defs;
  
  return {

    %{ $self->SUPER::default_options },

    'ensembl_codebase'      => $sd->ENSEMBL_HIVE_HOSTS_CODE_LOCATION,  
    'pipeline_name'         => 'ensembl_web_tools',
    'hive_use_triggers'     => 0,
    'pipeline_db'           => {
      '-host'                 =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'HOST'},
      '-port'                 =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PORT'}, 
      '-user'                 =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'USER'} || $sd->DATABASE_WRITE_USER,
      '-pass'                 =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
      '-dbname'               =>  $sd->multidb->{'DATABASE_WEB_HIVE'}{'NAME'},
      '-driver'               =>  'mysql',
    },
    'ticket_db'             => {
      '-host'                 =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
      '-port'                 =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
      '-user'                 =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'} || $sd->DATABASE_WRITE_USER,
      '-pass'                 =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
      '-dbname'               =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
    },

    map %{$_->can('default_options') ? $_->default_options($self) : {}}, $self->available_tools
  };
}

sub resource_classes {
  ## @override
  my $self = shift;
  return { map %{$_->resource_classes($self)}, $self->available_tools };
}

sub pipeline_analyses {
  ## @override
  my $self = shift;
  return [ map { @{$_->pipeline_analyses($self)} } $self->available_tools ];
}

1;

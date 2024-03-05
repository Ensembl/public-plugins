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

package EnsEMBL::Web::PipeConfig::Tools_conf;

use strict; 
use warnings;

use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

use parent qw(Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf);

sub new {
  ## @override
  ## @constructor
  ## Adds some extra info to the object and require the tools config packages
  my $self  = shift->SUPER::new(@_);
  my $sd    = $self->{'_species_defs'} = EnsEMBL::Web::SpeciesDefs->new;

  @{$self->{'_all_tools'}} = map dynamic_require("EnsEMBL::Web::ToolsPipeConfig::$_"), $sd->hive_tools_list;

  return $self;
}

sub species_defs {
  ## @return Species defs object
  return shift->{'_species_defs'};
}

sub all_tools {
  ## @return Array of all tools (whether or not they are available on this site)
  return @{$_[0]{'_all_tools'}};
}

sub default_options {
  ## @override
  my $self    = shift;
  my $hive_db = $self->species_defs->hive_db;

  return {

    %{ $self->SUPER::default_options },

    'pipeline_name'         => 'ensembl_web_tools',
    'hive_use_triggers'     => 0,
    'pipeline_db'           => {
      '-host'                 =>  $hive_db->{'host'},
      '-port'                 =>  $hive_db->{'port'},
      '-user'                 =>  $hive_db->{'username'},
      '-pass'                 =>  $hive_db->{'password'},
      '-dbname'               =>  $hive_db->{'database'},
      '-driver'               =>  'mysql',
    }
  };
}

sub resource_classes {
  ## @override
  my $self = shift;
  return { map %{$_->resource_classes($self)}, $self->all_tools };
}

sub pipeline_analyses {
  ## @override
  my $self = shift;
  return [ map { @{$_->pipeline_analyses($self)} } $self->all_tools ];
}

1;

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

package EnsEMBL::Web::ToolsPipeConfig::LD;

### Provides configs for VEP for tools pipeline

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ToolsPipeConfig);

sub logic_name        { 'LD'                                      }
sub runnable          { 'EnsEMBL::Web::RunnableDB::LD'            }
sub queue_name        { $SiteDefs::ENSEMBL_LD_QUEUE               }
sub is_farm           { !$SiteDefs::ENSEMBL_LD_RUN_LOCAL          }
sub farm_timeout       { $SiteDefs::ENSEMBL_LD_FARM_TIMEOUT         }
sub memory_usage      { $SiteDefs::ENSEMBL_LD_MEMORY_USAGE        }
sub analysis_capacity { $SiteDefs::ENSEMBL_LD_ANALYSIS_CAPACITY   }

1;

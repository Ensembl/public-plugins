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

package EnsEMBL::Web::Job::FileChameleon;

use strict;
use warnings;

use JSON qw(to_json);

use EnsEMBL::Web::Utils::FileHandler qw(file_put_contents);

use parent qw(EnsEMBL::Web::Job);

sub prepare_to_dispatch {
  ## @override
  my $self        = shift;
  
  my $rose_object     = $self->rose_object;
  my $job_data        = $rose_object->job_data;
  my $format          = $job_data->{format};
  my $source          = "chromosome|".lc($job_data->{species})."_ensembl_to_ucsc";

  my $config_content  = {
    "input_filter" => { 
        "source"      => $source,
        "seqname"     => "callback",
        "attributes"  => { 
          "gene_name" => "callback" 
        },
        "sequence"    => "seq_callback" 
    },
    "include" => ["file:///localsw/FileChameleon/examples/chromosome_plus_callbacks.conf"]
  };

  file_put_contents($rose_object->job_dir."/configuration.conf", to_json($config_content));

  return {
    'work_dir'    => $rose_object->job_dir,
    'output_file' => "FileChameleon_output.$format", #need to change the output file name to be the same as inputfile name with _converted
    'input_file'  => $job_data->{'url'},
    'format'      => $format,
    'config'      => "/configuration.conf",
    'code_root'   => $self->hub->species_defs->ENSEMBL_HIVE_HOSTS_CODE_LOCATION
  };
}

1;

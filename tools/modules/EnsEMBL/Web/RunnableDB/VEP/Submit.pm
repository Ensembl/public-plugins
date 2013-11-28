=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::RunnableDB::VEP::Submit;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::RunnableDB);

sub run {
  my $self = shift;
  
  # get global analysis params
  my $analysis_params = eval $self->analysis->parameters;
  my $cache_dir  = $analysis_params->{options}->{cache_dir};
  my $vep_script = $analysis_params->{options}->{script};
  my $perl_bin   = $analysis_params->{options}->{perl_bin};
  
  # get VEP options set on input form
  my $config = $self->param('config');
  my $option_str = '';
  while ( (my $option, my $value) =  each %$config ){
    next if !$option || !defined($value) || $value eq 'no';
    $option_str .= " --".$option;
    $option_str .= " ".$value unless $value eq 'yes';
  }
  
  my $command = "$perl_bin $vep_script --force --quiet --vcf --tabix --fork 4 --stats_text --dir $cache_dir --cache $option_str";
  #print STDERR $command;
  
  open(PIPE, "$command 2>&1 1>/dev/null |") or die($?);
  my $output;
  while(<PIPE>) { $output .= $_; }
  close PIPE;
  
  die($output) if $output;
  
  return;
}

1;

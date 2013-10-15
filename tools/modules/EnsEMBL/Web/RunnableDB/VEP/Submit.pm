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

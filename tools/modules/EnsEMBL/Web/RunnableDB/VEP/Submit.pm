package EnsEMBL::Web::RunnableDB::VEP::Submit;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  my $self = shift;
  my $ticket_id = $self->param('ticket');

  return;    
}

sub run {
  my $self = shift;
  
  my $cache_dir  = $self->param('vep_cache_dir');
  my $vep_script = $self->param('vep_script');
  my $perl_bin   = $self->param('vep_perl_bin');

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
  while(<PIPE>) {
    die($_) if /^error/i;
  }
  close PIPE;
  
  return;
}

1;

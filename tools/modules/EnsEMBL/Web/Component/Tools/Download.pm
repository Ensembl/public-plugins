package EnsEMBL::Web::Component::Tools::Download;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use Bio::Root::IO; 
use Bio::EnsEMBL::Utils::IO qw/iterate_file/;

sub _init { 
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content { 
  my $self = shift; 
  if ($self->hub->param('format') eq 'raw') {
    $self->print_raw_format;
  }
}


sub print_raw_format {
  my $self = shift;
  my $object = $self->object;  
  my $name = $self->hub->param('tk');
  my $filename = $self->hub->param('file');

  

  my $filepath = sprintf (  '%s/%s/%s/%s',
    $object->species_defs->ENSEMBL_TMP_DIR_BLAST,
    substr($name, 0, 6),
    substr($name, 6),
    $filename
  );


  iterate_file($filepath, sub {
    my ($line) = @_;
    print $line;
  });
}

1;

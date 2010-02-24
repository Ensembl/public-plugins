package EnsEMBL::Development::Object::Server;

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::Object;
our @ISA = qw(EnsEMBL::Web::Object);

sub get_environment {
  my $self = shift;
  return [ map { {'key'=>$_,'value'=>$ENV{$_}} } sort keys %ENV ];
}

1;


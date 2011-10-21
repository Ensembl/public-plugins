package EnsEMBL::Web::Object::UserDirectory;

use strict;

use base qw(EnsEMBL::Web::Object);

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->rose_objects($self->rose_manager('Group')->fetch_with_members($self->hub->species_defs->ENSEMBL_WEBADMIN_ID, 1));
  return $self;
}

1;
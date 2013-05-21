package EnsEMBL::Web::SpeciesDefs;

use strict;

sub set_userdb_details_for_rose {
  my $self = shift;
  
  $self->ENSEMBL_ORM_DATABASES->{'user'} = {
    'database'  => $self->ENSEMBL_USERDB_NAME,
    'host'      => $self->ENSEMBL_USERDB_HOST,
    'port'      => $self->ENSEMBL_USERDB_PORT,
    'username'  => $self->ENSEMBL_USERDB_USER,
    'password'  => $self->ENSEMBL_USERDB_PASS
  };
}

1;

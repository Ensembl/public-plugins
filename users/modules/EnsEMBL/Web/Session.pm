# $Id$

package EnsEMBL::Web::Session;

use strict;

use EnsEMBL::Web::Record;

sub receive_shared_user_data {
  my ($self, $id) = @_; 
  return EnsEMBL::Web::Record->new($id);
}

1;

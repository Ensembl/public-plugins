# $Id$

package EnsEMBL::Web::Session;

use strict;

use Digest::MD5 qw(md5_hex);

use EnsEMBL::Web::Record;

sub receive_shared_user_data {
  my ($self, $id, $checksum) = @_; 
  my $record = EnsEMBL::Web::Record->new($id);
  return $record && $record->type =~ /^(url|upload)$/ && $checksum eq md5_hex($record->code) ? $record : undef;
}

1;

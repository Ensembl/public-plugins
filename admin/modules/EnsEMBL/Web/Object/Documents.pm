package EnsEMBL::Web::Object::Documents;

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Admin::Tools::DocumentParser qw(parse_file);

use base qw(EnsEMBL::Web::Object);

sub new {
  my $self = shift->SUPER::new(@_);

  if (my $file_name = {@{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS}}->{$self->hub->function}) {
    try {
      $self->{'_parsed_file'} = parse_file($file_name->[1]);
    } catch {
      warn $_;
    };
  }

  return $self;
}

sub get_parsed_file {
  return shift->{'_parsed_file'};
}

sub available_documents {
  return [ map {ref $_ ? $_->[0] : $_} @{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS} ];
}

1;
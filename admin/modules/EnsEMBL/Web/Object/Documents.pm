package EnsEMBL::Web::Object::Documents;

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Admin::Tools::DocumentParser qw(parse_file);

use base qw(EnsEMBL::Web::Object);

sub caption             { return ({@{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS}}->{shift->function} || [])->[0] || 'Documents'  }
sub short_caption       { shift->caption;                                                                                   }
sub get_parsed_file     { return shift->{'_parsed_file'};                                                                   }
sub header_message      { return shift->{'_header_message'} || '';                                                          }
sub available_documents { return [ map {ref $_ ? $_->[0] : $_} @{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS} ];                  }

sub new {
  my $self  = shift->SUPER::new(@_);
  my $func  = $self->function;
  my $file  = {@{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS}}->{$func};

  if ($file) {
    if (-e $file->[1]) {
      my $do_update = $self->action eq 'Update';
      $file->[1]    =~ /(.+\/)([^\/]+)$/;
      my $dir       = `pwd`;
      chdir($1);
      my $filename  = $2;
      my $cvsstat   = `cvs status $filename`;
      $cvsstat      =~ /Status\:\s*([^\n]+)/;

      if ($do_update) {
        system("cvs up $filename") if $1 eq 'Needs Patch';
      } else {
        if ($1 eq 'Needs Patch') {
          $self->{'_header_message'} = sprintf('A newer version of the file is available in the CVS repository. Click <a href="%s">here</a> to update.', $self->hub->url({'action' => 'Update', 'function' => $func}));
        } else {
          $self->{'_header_message'} = "CVS status: $1";
        }
        try {
          $self->{'_parsed_file'} = parse_file($filename);
        } catch {
          $self->{'_header_message'} = "There was an error parsing the file:<br /><pre>$_</pre>";
          warn $_;
        };
      }
      chdir($dir);
    } else {
      $self->{'_header_message'} = "There was no document found corresponding to $func";
      warn "File does not exist: $file->[1]";
    }
  }

  return $self;
}

1;
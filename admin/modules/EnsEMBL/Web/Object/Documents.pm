package EnsEMBL::Web::Object::Documents;

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Admin::Tools::DocumentParser qw(parse_file);
use EnsEMBL::Admin::Tools::FileHandler qw(file_get_contents file_put_contents);

use base qw(EnsEMBL::Web::Object);

sub caption             { return 'Administration Documents'                                             }
sub short_caption       { shift->caption;                                                               }
sub get_raw_file        { return shift->{'_raw_file'};                                                  }
sub get_parsed_file     { return shift->{'_parsed_file'};                                               }
sub header_message      { return shift->{'_header_message'} || '';                                      }
sub available_documents { return [ map {$_} @{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS} ];                 }
sub document_title      { return ({@{$_[0]->available_documents}}->{$_[0]->function} || {})->{'title'}; }
sub saved_successfully  { return shift->{'_save_success'};                                              }

sub new {
  my $self  = shift->SUPER::new(@_);
  my $hub   = $self->hub;
  my $func  = $self->function;
  
  my $file  = {@{$self->available_documents}}->{$func};

  if ($file) {
    if (-e $file->{'location'}) {
      my $action          = $self->action;
      $file->{'location'} =~ /(.+\/)([^\/]+)$/;
      my $dir             = `pwd`;
      chdir($1);
      my $filename        = $2;
      my $cvsstatus       = $self->_get_cvs_status($filename);

      if ($action eq 'Update') {
        system('cvs', 'update', $filename) if $cvsstatus eq 'Needs Patch';

      } elsif ($action eq 'Save') {
        if ($cvsstatus eq 'Up-to-date') {
          try {
            file_put_contents($filename, $hub->param('post_document'));
            system('cvs', 'commit', '-m', sprintf("%s\nby %s via Admin Site", $hub->param('post_cvs'), $hub->user->email), $filename);
            $self->{'_save_success'} = 1;
          } catch {
            warn $_;
          };
        }

      } elsif ($action eq 'Preview') {
        if ($cvsstatus eq 'Up-to-date') {
          $self->{'_raw_file'} = $hub->param('post_document');
          try {
            $self->{'_parsed_file'} = parse_file([ split "\n", $self->{'_raw_file'} ]);
          } catch {
            $self->{'_header_message'} = 'There was an error parsing the modified file. Please try editing again.';
          };
        } else {
          $self->{'_header_message'} = 'The file needs to be synced with CVS repository before it can be edited.';
        }

      } elsif ($action eq 'Edit') {
        if ($cvsstatus eq 'Up-to-date') {
          $self->{'_raw_file'} = join '', file_get_contents($filename);
        } else {
          $self->{'_header_message'} = "The file needs to be synced with CVS repository before it can be edited.";
        }

      } else {
        if ($cvsstatus eq 'Needs Patch') {
          $self->{'_header_message'} = sprintf('A newer version of the file is available in the CVS repository. Click <a href="%s">here</a> to update.', $hub->url({'action' => 'Update', 'function' => $func}));
        } else {
          $self->{'_header_message'} = "CVS status: $cvsstatus";
        }
        try {
          $self->{'_parsed_file'} = parse_file($filename);
        } catch {
          $self->{'_header_message'} = "There was an error parsing the file:<br /><pre>$_</pre>";
        };
      }
      chop  $dir;
      chdir $dir;

    } else {
      $self->{'_header_message'} = "There was no document found corresponding to $func";    
      warn "File does not exist: $file->{'location'}";
    }
  } else {
    $self->{'_header_message'} = "There was no document found corresponding to $func";    
  }

  return $self;
}

sub _get_cvs_status {
  my ($self, $file) = @_;
  my $cvs_status    = {};
  my @cvs_status    = `cvs status $file`;
  for (@cvs_status) {
    if ($_ =~ /(Status|Sticky\s(Tag|Date))\:\s+([^\n]+)/) {
      $cvs_status->{$1} = $3;
    }
  };
  return 'Unknown' if $cvs_status->{'Status'} eq 'Unknown';
  $cvs_status->{"Sticky $_"} ne '(none)' and return "Sticky $_" for qw(Tag Date);
  return $cvs_status->{'Status'};
}

1;
=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Object::Documents;

use strict;

use File::Copy;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents file_put_contents);
use EnsEMBL::Admin::Tools::DocumentParser qw(parse_file);

use parent qw(EnsEMBL::Web::Object);

sub caption             { return 'Administration Documents'                                             }
sub short_caption       { shift->caption;                                                               }
sub get_raw_file        { return shift->{'_raw_file'};                                                  }
sub get_parsed_file     { return shift->{'_parsed_file'};                                               }
sub message             { return shift->{'_message'} || '';                                             }
sub message_code        { return shift->{'_message_code'};                                              }
sub available_documents { return [ map {$_} @{$SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS} ];                 }
sub document_title      { return ({@{$_[0]->available_documents}}->{$_[0]->function} || {})->{'title'}; }
sub saved_successfully  { return shift->{'_save_success'};                                              }

sub new {
  my $self      = shift->SUPER::new(@_);
  my $hub       = $self->hub;
  my $action    = $self->action;
  my $func      = $self->function;
  my $file      = {@{$self->available_documents}}->{$func} || {};

  my $dir       = ($file->{'location'} || '') =~ s/[^\/]+$//r;
  my $root      = `pwd` =~ s/\n//r;

  my $messages  = {
    'DIRECTORY_MISSING'     => "Error: The directory containing the document corresponding to $func is either missing or inaccessible.",
    'PROBLEM_ACCESSING_GIT' => 'Error: There was a problem accessing the GIT checkout directory for updating the document.',
    'GIT_DIRECTORY_MISSING' => "Error: The GIT checkout directory for syncing the documents could not be located.",
    'NO_GIT'                => 'Error: The server code base does not seem to be from a GIT repo.',
    'GIT_BRANCH_PROBLEM'    => 'Error: Git branch is not configured properly.',
    'ERROR_SYNCING'         => 'Error: unknown error occoured while syncing document file.',
    'DOCUMENT_MISSING'      => "Error: The document file corresponding to $func does not exist.",
    'NOT_IMPLEMENTED'       => 'Feature to edit a file is yet not implemented.'
  };

  # if any valid message code is already there in the URL, ignore further processing.
  my $msg_code  = $hub->param('msg');
  unless ($msg_code && exists $messages->{$msg_code}) {

    if (!($dir && -d $dir && chdir $dir)) {
      $self->{'_message_code'} = 'DIRECTORY_MISSING';

    } else {

      # get current branch name
      my $branch = `git rev-parse --abbrev-ref HEAD` =~ s/\n$//r;

      # If it's not a GIT repo
      if ($? >> 8) {
        $self->{'_message_code'} = 'NO_GIT';

      } elsif (!$branch || $branch ne $SiteDefs::WEBSITE_GIT_BRANCH) {
        $self->{'_message_code'} = 'GIT_BRANCH_PROBLEM';

      } else {
        my $git_root = `git rev-parse --show-toplevel` =~ s/\n|\/$//rg;
        my $git_copy = $git_root.($hub->species_defs->WEBSITE_GIT_FOLDER_SUFFIX || '-readonly');
        my $new_file = $file->{'location'} =~ s/^$git_root/$git_copy/r;

        if (!-d $git_copy) {
          $self->{'_message_code'} = 'GIT_DIRECTORY_MISSING';

        } else {
          if ($action eq 'Update') {

            if (!chdir $git_copy) {
              $self->{'_message_code'} = 'PROBLEM_ACCESSING_GIT';

            } else {
              `git checkout --force $branch; git fetch --all; git reset --hard origin/$branch`;

              if ($new_file eq $file->{'location'}) {
                $self->{'_message_code'} = 'ERROR_SYNCING';

              } elsif (!-e $new_file) {
                $self->{'_message_code'} = 'DOCUMENT_MISSING';

              } else {
                if (!copy($new_file, $file->{'location'})) {
                  $self->{'_message_code'} = 'DOCUMENT_MISSING';
                }
              }
            }
          } elsif ($action =~ /^(Save|Preview|Edit)$/) {
            ## TODO - Not implemented yet!

          } elsif ($action eq 'View') {
            if (!-e $new_file) {
              $self->{'_message_code'} = 'DOCUMENT_MISSING';

            } else {
              my @stat = stat $file->{'location'};
              $self->{'_message'} = sprintf('Document last updated at %s. Click <a href="%s">here</a> to update now.', $self->pretty_date($stat[9], 'simple_datetime'), $hub->url({'action' => 'Update', 'function' => $func}));
              try {
                $self->{'_parsed_file'} = parse_file($file->{'location'});
              } catch {
                $self->{'_message'} = "Error: There was an error parsing the file:<br /><pre>$_</pre>";
              };
            }
          }
        }
      }
    }
  }

  $self->{'_message'} ||= $messages->{$msg_code} || 'Unknown error';

  # cd back to the original dir
  chdir $root;

  return $self;
}

1;

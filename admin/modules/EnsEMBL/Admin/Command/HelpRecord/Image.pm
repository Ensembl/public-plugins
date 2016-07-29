=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Command::HelpRecord::Image;

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileSystem qw(copy_files);

use parent qw(EnsEMBL::Web::Command);

sub process {
  my $self      = shift;
  my $hub       = $self->hub;
  my $user      = $hub->user;
  my $object    = $self->object;
  my $function  = $hub->function;
  my $redirect  = {'action' => 'Images', 'function' => 'List'};
  my ($list, $error);

  try {
    $list = $object->get_help_images_list;
  } catch {
    $error = 1;
  };

  unless ($error) {
  
    # change to the images dir
    my $root = `pwd`;
    chdir $object->get_help_images_dir;

    my $file  = $hub->param('file');
    ($file)   = grep { $_->{'name'} eq $file } @$list if $file;

    # Upload new or replace existing
    if ($function eq 'Upload') {
      $redirect->{'function'} = 'View';
      $redirect->{'file'}     = $self->upload_file({'param' => 'upload', 'name' => $file ? $file->{'name'} : ''});

    # Push changes
    } elsif ($function eq 'Push') {

      my (@deleted, @modified, @new);
      foreach my $file ($hub->param('files')) {
        for (@$list) {
          if ($_->{'name'} eq $file) {
            push @deleted,  $_ if $_->{'status'} eq 'Deleted';
            push @modified, $_ if $_->{'status'} eq 'Modified';
            push @new,      $_ if $_->{'status'} eq 'New';
          }
        }
      }

      # git remove the deleted files
      if (@deleted) {
        unlink map { $_->{'name'}, $_->{'modified'} } @deleted;
        system('git', 'rm', map $_->{'name'}, @deleted);
      }

      # copy the modified files and add them to git
      if (@modified || @new) {
        if (@modified) {
          copy_files({ map { $_->{'modified'} => $_->{'name'} } @modified });
          unlink map { $_->{'modified'} } @modified;
        }
        system('git', 'add', map $_->{'name'}, @modified, @new);
      }

      # If we have something staged to commit in the current dir
      if (`git diff --name-only --staged .`) {
        if (!system('git', 'ensconfig', '--set', sprintf('%s <%s>', $user->name, $user->email))) { # force the logged in user to be author and committer for a shared git user
          if (!system('git', 'commit', '-m', $hub->param('message') || 'Committed via Admin Site', '.')) { # commit only stuff in current folder

            my $branch = `git rev-parse --abbrev-ref HEAD` =~ s/\R//r;
            my $tracking_remote = `git config branch.$branch.remote` =~ s/\R//r;
            system('git', 'push', $tracking_remote, 'HEAD') and throw exception('GitException', 'Could not commit changes.');

          } else {
            throw exception('GitException', 'Could not commit changes.');
          }
        } else {
          throw exception('GitException', 'Could not force the logged in user as the author.');
        }
      }

    # File specific operations
    } elsif ($file && grep {$_ eq $function} @{$file->{'action'}}) {

      # Reset any changes made to the file
      if ($function eq 'Reset') {
        unlink($file->{'modified'}) if $file->{'modified'};

      # Delete a file
      } elsif ($function eq 'Delete') {
        unlink($file->{'name'}, $file->{'modified'} || ());
      }
    }

    # reset folder location
    chop  $root;
    chdir $root;
  }

  return $self->ajax_redirect($hub->url($redirect));
}

sub upload_file {
  ## Uploads a file with given parameter from CGI and saves it with given name
  ## @param Hashref with following keys:
  ##  - param:    CGI param name that contains the uploaded file
  ##  - folder:   Folder to which the file has to be uploaded, defaults to current directory
  ##  - name:     Final name of the file (defaults to the name of the file uploaded)
  ## @return Name of the saved file
  my ($self, $params) = @_;
  my $hub   = $self->hub;
  my $fh    = $hub->param($params->{'param'});
  my $name  = $params->{'name'} || "$fh";
     $name  =~ s/\s+/_/;
     $name  =~ s/[^a-zA-Z0-9_.-]+//;

  throw exception('FileException', 'File could not be uploaded successfully') unless fileno $fh;

  open    (UPLOADFILE, '>', sprintf('%s/%s', $params->{'folder'} || '.', $name)) or throw exception('FileException', $!);
  binmode UPLOADFILE;
  print   UPLOADFILE while <$fh>;
  close   UPLOADFILE;

  return $name;
}

1;

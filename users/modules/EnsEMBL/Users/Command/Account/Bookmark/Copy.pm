=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Users::Command::Account::Bookmark::Copy;

### Command module to copy a group bookmark to user bookmarks
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_UNKNOWN_ERROR);

use parent qw(EnsEMBL::Users::Command::Account);

sub process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');
  my $group_id    = $hub->param('group');

  if ($bookmark_id && $group_id) {

    my ($bookmark, $owner) = $object->fetch_bookmark_with_owner($bookmark_id, $group_id);

    if ($owner && $bookmark->count) {
      $bookmark = $bookmark->clone_and_reset->data;
      $bookmark->{'click'} = 0;

      $user->add_record({'data' => $bookmark, 'type' => 'bookmark'})->save({'user' => $user});
      return $self->ajax_redirect($hub->url({'action' => 'Bookmark', 'function' => ''}));
    }
  }
  return $self->redirect_message(MESSAGE_UNKNOWN_ERROR, {'error' => 1});
}

1;

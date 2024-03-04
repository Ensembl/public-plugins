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

package EnsEMBL::Users::Command::Account::Bookmark::Remove;

### Command module to remvoe a bookmark record (user bookmark or group bookmark)
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(MESSAGE_CANT_DELETE_BOOKMARK MESSAGE_BOOKMARK_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');

  my ($bookmark, $owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 );

  if ($owner && $bookmark->count) {

    my $redirect_url = {'action' => 'Bookmark', 'function' => 'View'};

    if ($owner->record_type eq 'group') {
      if ($bookmark->created_by eq $user->user_id || $user->is_admin_of($owner)) {
        $redirect_url = {'action' => 'Groups', 'function' => 'View', 'id' => $owner->group_id};
      } else {
        return $self->redirect_message(MESSAGE_CANT_DELETE_BOOKMARK, {'error' => 1});
      }
    }

    $user->delete_records($bookmark);

    return $self->ajax_redirect($hub->url($redirect_url));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;

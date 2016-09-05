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

package EnsEMBL::Users::Command::Account::Bookmark::Save;

use strict;
use warnings;

use EnsEMBL::Users::Messages qw(MESSAGE_BOOKMARK_NOT_FOUND);

use parent qw(EnsEMBL::Users::Command::Account);

sub csrf_safe_process {
  my $self        = shift;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $user        = $hub->user;
  my $bookmark_id = $hub->param('id');

  if (my ($bookmark, $record_owner) = $object->fetch_bookmark_with_owner( $bookmark_id ? ($bookmark_id, $hub->param('group')) : 0 )) {

    # if we need to save a new copy of the bookmark
    if ($record_owner->record_type eq 'group' && ($hub->param('save_new') || !($user->is_admin_of($record_owner) || $bookmark->created_by eq $user->user_id))) {
      $bookmark = $bookmark->clone_and_reset;
      $bookmark->click(0);
    }

    $bookmark->$_($hub->param($_) || '') for qw(name description url object);
    $bookmark->save({'user' => $user});

    return $self->ajax_redirect($hub->url($record_owner->record_type eq 'group'
      ? {'action' => 'Groups',    'function' => 'View', 'id' => $record_owner->group_id}
      : {'action' => 'Bookmark',  'function' => 'View'}
    ));

  } else {
    return $self->redirect_message(MESSAGE_BOOKMARK_NOT_FOUND, {'error' => 1});
  }
}

1;

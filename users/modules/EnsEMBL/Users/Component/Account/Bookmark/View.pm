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

package EnsEMBL::Users::Component::Account::Bookmark::View;

### Page for a logged in user to view his bookmarks
### @author hr5

use strict;
use warnings;

use parent qw(EnsEMBL::Users::Component::Account);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $user            = $hub->user;
  my $bookmarks       = $user->bookmarks;
  my $group_bookmarks = [ map @{$_->bookmarks}, @{$user->groups} ];

  return join '',
    $self->js_section({
      'heading'           => 'My bookmarks',
      'heading_links'     => [{
        'href'              => {qw(action Bookmark function Add)},
        'title'             => 'Add a bookmark',
        'sprite'            => 'bookmark_icon'
      }],
      'subsections'       => [ @$bookmarks ? $self->bookmarks_table({'bookmarks' => $bookmarks}) : $self->no_bookmark_message ]
    }), @$group_bookmarks ?
    $self->js_section({
      'heading'           => 'Shared bookmarks',
      'subsections'       => [ $self->bookmarks_table({'bookmarks' => $group_bookmarks, 'shared' => 1}) ]
    }) : ()
  ;
}

1;
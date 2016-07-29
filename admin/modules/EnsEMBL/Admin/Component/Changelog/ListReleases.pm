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

package EnsEMBL::Admin::Component::Changelog::ListReleases;

### Module to display list of all releases

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $is_pull = $hub->param('pull') ? 1 : 0;
  my $cur_rel = $object->current_release;

  my $list    = join '', map {
    $_ = $_->release_id;
    $is_pull && $_ >= $cur_rel ? () : sprintf('<li><a href="%s">%s release %s</a></li>',
      $hub->url({'action' => 'List', 'release' => $_, $is_pull ? ('pull' => 1) : ()}),
      $is_pull ? 'Copy a declaration from ' : 'View all declarations for ',
      $_
    );
  } @{$object->rose_objects};

  return $list ? sprintf('<h2>%s releases</h2><ul>%s</ul>', $is_pull ? 'Previous' : 'All', $list) : '<h2>Releases not found</h2><p>No previous releases were found in the database</p>';

}

1;
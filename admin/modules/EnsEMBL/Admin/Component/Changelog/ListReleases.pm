package EnsEMBL::Admin::Component::Changelog::ListReleases;

### Module to display list of all releases

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

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
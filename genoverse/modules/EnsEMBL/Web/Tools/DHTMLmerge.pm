=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;
use warnings;

use EnsEMBL::Web::Utils::PluginInspector qw(current_plugin);

use previous qw(get_filegroups);

use constant GENOVERSE_VERSION => 'v2.3';

my $GENOVERSE_FILES_ORDER = {
  'css' => [qw(
    controlPanel.css
    fileDrop.css
    font-awesome.css
    fullscreen.css
    genoverse.css
    hoverLabels.css
    karyotype.css
    resizer.css
    tooltips.css
    trackControls.css
  )],
  'js' => [qw(
    Genoverse.js
    lib/jquery.mousehold.js
    lib/jquery.mousewheel.js
    lib/rtree.js
    Track.js
    Track/Model.js
    Track/View.js
    Track/Controller.js
    Track/Model
    Track/View
    Track/Controller
    Track/library/Static.js
    Track/library
    plugins
  )]
};

sub get_filegroups {
  ## @override
  ## For genoverse, the code inside genoverse plugin's dir htdocs/genoverse/vX.X is synced from the genoverse
  ## repository without any changes. So in order to override some default genoverse functionality in Ensembl,
  ## there's a different folder 'ensembl' inside genoverse plugin's htdocs/genoverse folder. To make sure the
  ## code overrides the main genoverse one, it needs to be loaded after the genoverse code. Also if any other
  ## plugin wants to override some behaviour from genoverse, it should be able to do that by overriding the
  ## files in it's own 'ensembl' folder, but should not be allowed access to override the vX.X folder.
  my ($species_defs, $type) = @_;

  my @file_groups     = PREV::get_filegroups($species_defs, $type);
  my $genoverse_path  = current_plugin->{'path'};
     $genoverse_path  = sprintf '%s/genoverse/%s', grep(m/^$genoverse_path/, @{$species_defs->ENSEMBL_HTDOCS_DIRS || []}), GENOVERSE_VERSION;

  my @files;

  push @files, @{_get_genoverse_files($genoverse_path, $type)};                         # first load genoverse core folder from genoverse plugin only
  push @files, @{get_files_from_dir($species_defs, $type, "genoverse/ensembl/$type")};  # then load files to override the default genoverse files from all plugins

  return @file_groups, {
    'group_name'  => 'genoverse',
    'files'       => \@files,
    'condition'   => sub { return !!grep $_->[-1] eq 'genoverse', @{$_[0]->components}; },
    'ordered'     => 1
  };
}

sub _get_genoverse_files {
  ## @private
  my ($genoverse_path, $type) = @_;

  my $order = $GENOVERSE_FILES_ORDER->{$type};
  my $ls    = list_dir_contents("$genoverse_path/$type", {'recursive' => 1, 'absolute_path' => 1});
  my @files = map { my $path = "$genoverse_path/$type/$_"; -e $path ? -f $path ? $path : grep { $_ =~ /^$path\// && -f $_ } @$ls : (); } @$order;

  return \@files;
}

1;

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

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;
use warnings;

use EnsEMBL::Web::Utils::PluginInspector qw(get_all_plugins current_plugin);

use previous qw(get_filegroups);

use constant GENOVERSE_VERSION => 'v2.3';

my $GENOVERSE_FILES_ORDER = {
  'css' => [qw(
    genoverse.css
    controlPanel.css
    fileDrop.css
    font-awesome.css
    fullscreen.css
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
  ## code overrides the main genoverse one, each file from the 'ensembl' folder needs to be loaded immidiately
  ## after the corresponding core file is loaded. Also if there are further plugins to any of the files, they
  ## need to be loaded immidiately after the ones in 'ensembl' folder. To add to the complexity, all files
  ## should be ordered according to the order specified in GENOVERSE_FILES_ORDER and the files that are not
  ## mentioned in GENOVERSE_FILES_ORDER should be ignored from the 'genoverse' code.
  my ($species_defs, $type) = @_;

  my @file_groups     = PREV::get_filegroups($species_defs, $type);

  # ie7css, images, ...
  return @file_groups unless $GENOVERSE_FILES_ORDER->{$type};

  my @files_order     = map { s/\/$//r } @{$GENOVERSE_FILES_ORDER->{$type}};
  my $current_plugin  = current_plugin;
  my $genoverse_path  = sprintf '%s/htdocs/genoverse/%s/%s', $current_plugin->{'path'}, GENOVERSE_VERSION, $type;

  # First load the genoverse core folder from genoverse plugin excluding the files that are not mentioned
  # in GENOVERSE_FILES_ORDER (files are not yet arranged in the required order)
  my $all_core_files  = list_dir_contents($genoverse_path, {'recursive' => 1, 'absolute_path' => 1});
  my %genoverse_files = map { s/$genoverse_path\/*//r => [ $_ ] }
                        map { my $path = "$genoverse_path/$_"; -e $path ? -f $path ? $path : grep { m/^$path\/.+\.$type$/ && -f } @$all_core_files : (); } @files_order;

  # Now load files from all plugins to override the default genoverse files and keep
  # the plugin files for each file in a cascaded manner next to the original file
  for (@{get_all_plugins()}) {

    # since genoverse file names can be same (we don't use numbered prefixes), if we keep the entire path same, the files
    # will get over written when loading them in debug=js mode, so sub folder name should be kept different
    # ie. for each plugin, the sub folder is drived from the package name of that plugin
    # eg. ensembl_sanger for sanger plugin (EnsEMBL::Sanger).
    my $plugin_path = sprintf '%s/htdocs/genoverse/%s/%s', $_->{'path'}, $_->{'package'} eq $current_plugin->{'package'} ? 'ensembl' : lc $_->{'package'} =~ s/\:\:/_/r, $type;

    # now loop through all the plugin sub folders and distribute the files among the original hash
    # keys keeping the plugin file next to the original file in the individual mini array
    for (grep -f "$plugin_path/$_" && m/\.$type$/, @{-d $plugin_path ? list_dir_contents($plugin_path, {'recursive' => 1}) : []}) {
      push @{$genoverse_files{$_}}, "$plugin_path/$_";
    }
  }

  # create a sort algo that gives priority to the files in top level dirs first (and alphabetically if level is same)
  my $breadth_first_sort = sub { @{[$a =~ /\//g]} <=> @{[$b =~ /\//g]} || lc $a cmp lc $b };

  # Now rearrange the files according to the required order
  my @files;
  foreach my $path (@files_order) {

    # files are easy, but with folders, get all the files matching the folder's path and
    # then give priority according to sort algo created earlier
    for (exists $genoverse_files{$path} ? $path : sort $breadth_first_sort grep { m/^$path\// } keys %genoverse_files) {

      # delete the files from the original hash once they are added to the list
      # to avoid adding them again when another sub-folder is matching to the file path
      push @files, @{delete $genoverse_files{$_}};
    }
  }

  # Anything that exists in the 'ensembl' folder (or the plugins) but is not listed in
  # the GENOVERSE_FILES_ORDER gets added in the end.
  push @files, @{delete $genoverse_files{$_}} for sort $breadth_first_sort keys %genoverse_files;

  # finally
  return @file_groups, {
    'group_name'  => 'genoverse',
    'files'       => \@files,
    'condition'   => sub { return !!grep $_->[-1] eq 'genoverse', @{$_[0]->components}; },
    'ordered'     => 1
  };
}

1;

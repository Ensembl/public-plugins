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

use previous qw(get_filegroups);

sub get_filegroups {
  ## @override
  my ($species_defs, $type) = @_;

  my @groups = PREV::get_filegroups($species_defs, $type);

  return @groups if $type eq 'css';

  my @ordered_files;

  foreach my $file (@{genoverse_files_order()}) {
    foreach my $path (grep -e, map "$_/genoverse/$file", reverse grep !m/biomart/, @{$species_defs->ENSEMBL_HTDOCS_DIRS || []}) {
      if (-d $path) {
        push @ordered_files, grep -f, map "$path/$_", sort { lc $a cmp lc $b } @{list_dir_contents($path, {'recursive' => 1})};
      } else {
        push @ordered_files, $path;
      }
    }
  }

  return @groups, {
    'group_name'  => 'genoverse',
    'files'       => \@ordered_files,
    'condition'   => sub { return !!grep $_->[-1] eq 'genoverse', @{$_[0]->components}; },
    'ordered'     => 1
  };
}

sub genoverse_files_order {
  return [
    'Genoverse.js',
    'Ensembl/Genoverse.js',
    'Ensembl/GenoverseMobile.js',
    'Track.js',
    'Ensembl/Track.js',
    'Track/Controller.js',
    'Track/Model.js',
    'Track/View.js',
    'Ensembl/MVC.js',
    'Track/library/File.js',
    'Track/library/Static.js',
    'Track/Controller/Stranded.js',
    'Track/Model/Stranded.js',
    'Track/Controller',
    'Track/Model',
    'Track/View',
    'Track/library',
    'lib',
    'plugins',
    'Ensembl',
  ];
}


1;

=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Tools::JavascriptOrder;

use strict;

sub new {
  my ($class, $self) = @_;
  bless $self, $class;
  $self->{'dir'} = [ split 'modules', __FILE__ ]->[0] . 'htdocs';
  return $self;
}

sub order {
  my $self = shift;
  $self->add_dir($_) for reverse @{$self->{'species_defs'}->ENSEMBL_HTDOCS_DIRS};
  return @{$self->{'files'}};
}

sub add_dir {
  my ($self, $root) = @_;
  my $dir   = "$root/genoverse";
  my $order = {
    files => [
      'Genoverse.js',
      'Ensembl/Genoverse.js',
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
    ],
    dirs => [
      'Track/Controller',
      'Track/Model',
      'Track/View',
      'Track/library',
      'lib',
      'plugins',
      'Ensembl',
    ]
  };
  
  if (-e $dir && -d $dir) {
    $self->add_file("$dir/$_")    for @{$order->{'files'}};
    $self->add_sub_dir("$dir/$_") for @{$order->{'dirs'}};
  }
}

sub add_sub_dir {
  my ($self, $dir) = @_;
  
  if (-e $dir && -d $dir) {
    opendir DH, $dir;
    my @files = readdir DH;
    closedir DH;
    
    foreach (sort { -d "$dir/$a" <=> -d "$dir/$b" || lc $a cmp lc $b } grep /\w/, @files) {
      if (-d "$dir/$_") {
        $self->add_sub_dir("$dir/$_");
      } elsif (-f "$dir/$_" && /\.js$/) {
        $self->add_file("$dir/$_");
      }
    }
  }
}

sub add_file { 
  my ($self, $src) = @_;
  
  return unless $src;
  return if $self->{'sources'}{$src}++;
  
  $src =~ s/\/?$self->{'dir'}// unless $self->{'absolute_path'};
  
  push @{$self->{'files'}}, $src;
}

1;

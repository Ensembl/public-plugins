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

package EnsEMBL::Web::Object::HelpRecord;

use strict;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileSystem qw(create_path remove_directory remove_empty_path copy_dir_contents copy_files list_dir_contents);

use parent qw(EnsEMBL::Web::Object::DbFrontend);

sub record_type {
  ## Gets the type of the record(s) requested for i.e. - glossary, view, movie, faq
  my $self = shift;

  my $type = lc $self->hub->function;
  return $type && grep({$type eq $_} qw(glossary view movie faq)) ? $type : undef;
}

sub fetch_for_display {
  my $self   = shift;
  return $self->SUPER::fetch_for_display(@_) if $self->hub->param('id');

  my $type   = $self->record_type;
  $self->SUPER::fetch_for_display({'query' => ['type' => $type]}) if $type;

  my $rose_objects  = $self->rose_objects;
  my $order_by_1    = {qw(glossary word view ensembl_object movie title faq category)}->{$type};
  my $order_by_2    = {qw(view ensembl_action faq question)}->{$type} || 0;

  $self->rose_objects([ sort { ($a->virtual_column_value($order_by_1) cmp $b->virtual_column_value($order_by_1)) || $order_by_2 && ($a->virtual_column_value($order_by_2) cmp $b->virtual_column_value($order_by_2))} @$rose_objects ]) if $rose_objects;
}

sub fetch_for_list {
  return shift->fetch_for_display(@_);
}

sub get_help_images_dir {
  ## Returns the absolute address of the directory that contains help images
  my $sd = shift->hub->species_defs;
  return $sd->ENSEMBL_WEBROOT.'/htdocs'.$sd->ENSEMBL_HELP_IMAGE_ROOT =~ s/\/$//r;
}

sub get_help_images_list {
  ## Returns list of all the images in the help folder along with some extra info about each image
  my $self      = shift;
  my $dir       = $self->get_help_images_dir or throw exception('Images directory has not been configured. Please configure it in your plugins.');
  my $hub       = $self->hub;
  my $function  = $hub->function;
  my $root      = `pwd`;
  my $suffix    = '_sanger_plugin_tmp';

  chdir $dir or throw exception("Error getting to images directory: $!");

  my %list;

  my $repos_path      = `git rev-parse --show-toplevel` =~ s/\/?\R*$//gr;
  my $repos_name      = $repos_path =~ s/.+\///rg;
  my $current_branch  = `git rev-parse --abbrev-ref HEAD` =~ s/\R//r;
  my $branch          = $current_branch =~ s/$suffix$//r;
  my $tmp_branch      = "$branch$suffix";
  my $tmp_dir         = "$dir$suffix";
  my $tracking_branch = `git config branch.$branch.merge` =~ s/(refs\/heads\/|\R)//rg;
  my $tracking_remote = `git config branch.$branch.remote` =~ s/\R//r;

  # the current branch needs to be tracking one in order to push changes to remote
  throw exception("The current branch on $repos_name is not tracking to any remote branch. Please checkout your GIT repository to a tracking branch.") unless $tracking_branch && $tracking_remote;

  # Make sure it's on the actual branch
  `git checkout --force $branch` unless $current_branch eq $branch;

  # It's likely that anything that is modified on the current branch in images folder is modified by the website user, so preserve those changes
  my %modified = map { $_ => -e $_ ? $_ =~ s/([^\/]+)$/_modified.$1/r : s/([^\/]+)$/_deleted.$1/r } map { join '/', $repos_path, $_ =~ s/\R//r } `git diff --name-only .`;
  if (my @backup = map { $modified{$_} !~ /\/_deleted./ ? ($_ => delete $modified{$_}) : () } keys %modified) {
    copy_files({ @backup });
  }

  # create a new temp branch and update it to latest remote version
  `git reset HEAD --hard`;
  `git fetch $tracking_remote`;
  `git checkout -B $tmp_branch $tracking_remote/$tracking_branch`;

  # backup the latest files to a temporary dir
  copy_dir_contents($dir, $tmp_dir, {'create_path' => 1, 'recursive' => 1});

  # now checkout on the original branch, delete the temp branch and get the modified files from the backup folder
  `git checkout --force $branch`;
  `git branch -d $tmp_branch`;
  copy_dir_contents($tmp_dir, $dir, {'recursive' => 1});
  remove_directory($tmp_dir);

  # Rename any files deleted by the user that got checked out again
  copy_files(\%modified);

  # ok, now we have the folder with latest changes from remote and any local modifications as seperate copies
  for (@{list_dir_contents($dir)}) {
    next if -d; # skip directories
    next if $_ =~ /^(_modified|_deleted)/;

    my $modified = "_%s.$_";
    my $status;

    for (qw(modified deleted)) {
      if (-e sprintf "$dir/$modified", $_) {
        $modified = sprintf $modified, $_;
        $status   = ucfirst $_;
        last;
      }
    }

    if (!$status) {
      $modified = undef;
      $status   = `git ls-files $_` ? 'Up-to-date' : 'New';
    }

    $list{$_} = {
      'name'      => $_,
      'writable'  => -W || 0,
      'size'      => -s,
      'status'    => $status,
      'modified'  => $modified,
      'action'    => [ 'View', $status !~ /deleted/i ? qw(Replace Delete) : (), $status =~ /deleted|modified/i ? 'Reset' : () ]
    };
  }

  chop  $root;
  chdir $root;

  return [ map $list{$_}, sort keys %list ];
}

sub get_image_details {
  ## Gets MD5 and dimensions of an image file
  ## @param File name
  ## @return Hashref with keys md5 and dimensions
  my ($self, $file) = @_;

  my $file_path = sprintf '%s/%s', $self->get_help_images_dir, $file;
  my $info = {};

  if (-W $file_path) {

    # MD5
    open IMG, "<$file_path" or throw exception("Error reading image $file: $!");
    my $ctx = Digest::MD5->new;
    $ctx->addfile (*IMG);
    $info->{'md5'} = substr $ctx->hexdigest, 0, 8;
    close IMG;

    # Dimensions
    `file $file_path` =~ /\s+([0-9]+)\s+x\s+([0-9]+)/;
    $info->{'dim'} = {'x' => $1, 'y' => $2} if $1 && $2;
  }

  return $info;
}

sub get_count {
  ## @overrides
  my $self = shift;
  my $type = $self->record_type;
  return 0 unless $type;
  return $self->SUPER::get_count({'query' => ['type' => $type]});
}

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager(qw(Website HelpRecord));
}

sub show_fields {
  ## @overrides
  my $self = shift;
  my $type = $self->rose_object ? $self->rose_object->type : $self->record_type;
  my @datamap;

  if ($type eq 'glossary') {
    @datamap = (
      'word'           => {'label' => 'Word',            'type' => 'string'  },
      'expanded'       => {'label' => 'Expanded',        'type' => 'text',     'cols' => 60, 'rows' => 5},
      'meaning'        => {'label' => 'Meaning',         'type' => 'html',     'cols' => 60, 'rows' => 5,   'class' => '_tinymce'}
    );
  }
  elsif ($type eq 'view') {
    @datamap = (
      'help_links'     => {'label' => 'Linked URLs',     'type' => 'checklist', 'multiple' => 1},
      'content'        => {'label' => 'Content',         'type' => 'html',     'cols' => 60, 'rows' => 40,  'class' => '_tinymce _tinymce_h_600'}
    );
  }
  elsif ($type eq 'movie') {
    @datamap = (
      'title'          => {'label' => 'Title',           'type' => 'string'  },
      'help_record_id' => {'label' => 'Movie ID',        'type' => 'noedit', 'value' => '<i>to be assigned</i>', 'is_html' => 1 },
      'youtube_id'     => {'label' => 'Youtube ID',      'type' => 'string'  },
      'youku_id'       => {'label' => 'Youku ID',        'type' => 'string'  },
      'list_position'  => {'label' => 'List position',   'type' => 'int'     },
      'length'         => {'label' => 'Length',          'type' => 'string'  }
    );
  }
  elsif ($type eq 'faq') {
    @datamap = (
      'category'       => {'label' => 'Category',        'type' => 'dropdown', 'values' => [
        {'value' => 'archives',       'caption' => 'Archives'                     },
        {'value' => 'genes',          'caption' => 'Genes'                        },
        {'value' => 'assemblies',     'caption' => 'Genome assemblies'            },
        {'value' => 'comparative',    'caption' => 'Comparative genomics'         },
        {'value' => 'regulation',     'caption' => 'Regulation'                   },
        {'value' => 'variation',      'caption' => 'Variation'                    },
        {'value' => 'data',           'caption' => 'Export, uploads and downloads'},
        {'value' => 'z_data',         'caption' => 'Other data'                   },
        {'value' => 'core_api',       'caption' => 'Core API'                     },
        {'value' => 'compara_api',    'caption' => 'Compara API'                  },
        {'value' => 'variation_api',  'caption' => 'Variation API'                },
        {'value' => 'regulation_api', 'caption' => 'Regulation API'               }
      ]},
      'question'       => {'label' => 'Question',        'type' => 'html',     'cols' => 80,  'class' => '_tinymce'},
      'answer'         => {'label' => 'Answer',          'type' => 'html',     'cols' => 80,  'class' => '_tinymce'}
    );
  }

  return [
    @datamap,
    'keyword'               => {'label' => 'Keyword',         'type' => 'text',     'cols' => 60},
    'status'                => {'label' => 'Status',          'type' => 'dropdown'},
  ];
}

sub show_columns {
  ## @overrides
  my $self = shift;
  my $type = $self->rose_object ? $self->rose_object->type : $self->record_type;
  my @datamap;

  if ($type eq 'glossary') {
    @datamap = (
      'word'                => {'title' => 'Word'},
      'expanded'            => {'title' => 'Expanded'},
    );
  }
  elsif ($type eq 'view') {
    @datamap = (
      'help_links'          => {'title' => 'Help Links'}
    );
  }
  elsif ($type eq 'movie') {
    @datamap = (
      'title'               => {'title' => 'Title'},
      'help_record_id'      => {'title' => 'Movie ID', 'width' => '100px'},
      'youtube_id'          => {'title' => 'Youtube ID'},
      'youku_id'            => {'title' => 'Youku ID'},
    );
  }
  elsif ($type eq 'faq') {
    @datamap = (
      'category'            => {'title' => 'Category'},
      'question'            => {'title' => 'Question'},
    );
  }

  return [
    @datamap,
    'keyword'               => {'title' => 'Keyword'},
    'status'                => {'title' => 'Status'},
  ];
}

sub record_name {
  my $type  = shift->record_type;
  return [ map {'singular' => "$_", 'plural' => "${_}s"}, {'movie' => 'Movie', 'faq' => 'FAQ', 'glossary' => 'Word', 'view' => 'Page view'}->{$type} ]->[0] if $type;
  return {qw(singular Record plural Records)};
}

sub create_empty_object {
  ## @overrides
  ## Adds the type to the empty object before returning it
  my $self = shift;
  my $type = $self->record_type;
  return unless $type; ## TODO - throw exception here
  my $empty_object = $self->SUPER::create_empty_object(@_);
  $empty_object->type($type);
  return $empty_object;
}

sub get_fields {
  ## @overrides
  ## This ignores caching for get_fields method
  my $self = shift;
  delete $self->{'_dbf_show_fields'};
  return $self->SUPER::get_fields(@_);
}

sub permit_delete {
  ## @overrides
  return 'delete';
}

1;

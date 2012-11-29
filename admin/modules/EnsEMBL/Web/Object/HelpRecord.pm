package EnsEMBL::Web::Object::HelpRecord;

use strict;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Web::Object::DbFrontend);

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
  return $sd->ENSEMBL_SERVERROOT.'/htdocs'.$sd->ENSEMBL_HELP_IMAGE_ROOT;
}

sub get_help_images_list {
  ## Returns list of all the images in the help folder along with some extra info about each image
  my $self      = shift;
  my $dir       = $self->get_help_images_dir or throw exception('Images directory has not been configured. Please configure it in your plugins.');
  my $hub       = $self->hub;
  my $function  = $hub->function;
  my $root      = `pwd`;

  my %list;

  chdir $dir or throw exception("Error getting to images directory: $!");

  open ENTRIES, '<', 'CVS/Entries' or throw exception("Error reading CVS entries file: $!");
  my %cvs_entries;
  for (<ENTRIES>) {
    chop;
    my ($type, $name, $rev, $timestamp, $options, $tagdate) = split '/', $_;
    next if $type eq 'D';
    $cvs_entries{$name} = $tagdate && $tagdate =~ /^T(.+)/ ? $1 : undef;
  }
  close ENTRIES;

  opendir IMAGES_DIR, '.';

  for (readdir IMAGES_DIR) {
    next if -d; # skip directories

    $list{$_} = {
      'name'      => $_,
      'writable'  => -W || 0,
      'size'      => -s,
      'cvs'       => exists $cvs_entries{$_} ? _get_cvs_status($_) : 'New',
      'tag'       => delete $cvs_entries{$_}
    };

    if ($list{$_}{'writable'} && $function eq 'View' && $hub->param('file') eq $_) {
      open IMG, "<$_" or throw exception("Error reading image $_: $!");
      my $ctx = Digest::MD5->new;
      $ctx->addfile (*IMG);
      $list{$_}{'md5'} = substr $ctx->hexdigest, 0, 8;
      close IMG;

      if ($list{$_}{'cvs'} eq 'Up-to-date' && !$list{$_}{'tag'}) {
        `file $_` =~ /\s+([0-9]+)\s+x\s+([0-9]+)/;
        $list{$_}{'dim'} = {'x' => $1, 'y' => $2} if $1 && $2;
      }
    }
  }

  closedir IMAGES_DIR;

  for (keys %cvs_entries) { # if any file doesn't exist on file system but is in cvs entries
    $list{$_} = {
      'name'      => $_,
      'writable'  => 1,
      'missing'   => 1,
      'cvs'       => _get_cvs_status($_)
    };
  }

  chop  $root;
  chdir $root;

  ## validate actions for each file
  for my $file (values %list) {
    if ($file->{'writable'}) {
      $file->{'action'} = [ $file->{'missing'} ? () : 'View' ];
      if ($file->{'cvs'} =~ /^(Needs (Patch|Checkout))$/ || $file->{'tag'}) {
        push @{$file->{'action'}}, 'Update';
      } elsif ($file->{'cvs'} =~ /^(Locally Modified|New)$/) {
        push @{$file->{'action'}}, 'Commit', 'Delete', 'Upload';
      } elsif ($file->{'cvs'} eq 'Up-to-date') {
        push @{$file->{'action'}}, 'Upload';
      } elsif ($file->{'cvs'} eq 'Needs Merge') {
        push @{$file->{'action'}}, 'Delete';
      }
    }
  }

  return [ map $list{$_}, sort keys %list ];
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
  return shift->rose_manager('HelpRecord');
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

sub _get_cvs_status {
  ## @private
  my $file        = shift;
  my @cvs_status  = `cvs status $file`;
  $_ =~ /Status: ([^\n]+)/ and return $1 for @cvs_status;
}

1;

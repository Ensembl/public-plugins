package EnsEMBL::Web::Object::HelpRecord;

use strict;

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
  return $type ? $self->SUPER::fetch_for_display({'query' => ['type' => $type]}) : $self->rose_objects([]);
}

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('HelpRecord');
}

sub show_fields {
  my $self = shift;
  my $type = $self->rose_object ? $self->rose_object->type : $self->record_type;
  my @datamap;

  if ($type eq 'glossary') {
    @datamap = (
      'data.word'           => {'label' => 'Word',            'type' => 'string'  },
      'data.expanded'       => {'label' => 'Expanded',        'type' => 'text'    },
      'data.meaning'        => {'label' => 'Meaning',         'type' => 'text'    }
    );
  }
  elsif ($type eq 'view') {
    @datamap = (
      'data.ensembl_object' => {'label' => 'Ensembl object',  'type' => 'string'  },
      'data.ensembl_action' => {'label' => 'Ensembl action',  'type' => 'string'  },
      'data.content'        => {'label' => 'Content',         'type' => 'text'    }
    );
  }
  elsif ($type eq 'movie') {
    @datamap = (
      'data.title'          => {'label' => 'Title',           'type' => 'string'  },
      'data.youtube_id'     => {'label' => 'Youtube ID',      'type' => 'string'  },
      'data.list_position'  => {'label' => 'List position',   'type' => 'int'     },
      'data.length'         => {'label' => 'Length',          'type' => 'string'  }
    );
  }
  elsif ($type eq 'faq') {
    @datamap = (
      'data.category'       => {'label' => 'Category',        'type' => 'dropdown', 'values' => [
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
      'data.question'       => {'label' => 'Question',        'type' => 'text'    },
      'data.answer'         => {'label' => 'Answer',          'type' => 'text',     'notes' => 'Please make sure the text above is valid XHTML'}
    );
  }

  return [
    @datamap,
    'keyword'               => {'label' => 'Keyword',         'type' => 'text'    },
    'status'                => {'label' => 'Status',          'type' => 'dropdown'},
  ];
}

sub show_columns {
  return [];
}

sub record_name {
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

1;

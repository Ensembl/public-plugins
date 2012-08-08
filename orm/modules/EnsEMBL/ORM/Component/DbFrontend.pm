package EnsEMBL::ORM::Component::DbFrontend;

### NAME: EnsEMBL::ORM::Component::DbFrontend;
### Base class for components that make up the Ensembl DbFrontend CRUD interface 

### STATUS: Under Development

### DESCRIPTION:
### This module contains a lot of generic HTML/form generation code that is shared between DbFrontend CRUD pages.

use strict;
use warnings;

use Rose::DateTime::Util qw(parse_date format_date);
use EnsEMBL::ORM::Rose::Field;

use base qw(EnsEMBL::Web::Component);

use constant {
  _JS_CLASS_DBF_RECORD        => '_dbf_record',
  _JS_CLASS_RESPONSE_ELEMENT  => '_dbf_response',
  _JS_CLASS_EDIT_BUTTON       => '_dbf_button',
  _JS_CLASS_ADD_BUTTON        => '_dbf_button',
  _JS_CLASS_DELETE_BUTTON     => '_dbf_delete',
  _JS_CLASS_CANCEL_BUTTON     => '_dbf_cancel',
  _JS_CLASS_PREVIEW_FORM      => '_dbf_preview',
  _JS_CLASS_SAVE_FORM         => '_dbf_save',
  _JS_CLASS_ADD_FORM          => '_dbf_add',
  _JS_CLASS_DATASTRUCTURE     => '_datastructure',
  _JS_CLASS_LIST_TABLE        => '_dbf_list',
  _JS_CLASS_LIST_ROW_HANDLE   => '_dbf_row_handle',
  _JS_CLASS_DATATABLE         => 'data_table no_col_toggle',
  
  _FLAG_NO_CONTENT            => '_dbf_no_content',
  _FLAG_RECORD_BUTTONS        => '_dbf_record_buttons'
};

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  ## Returns content HTML
  return shift->content_tree->render;
}

sub content_tree {
  ## Returns content html's dom tree
  ## Override in the child classes
  my $self    = shift;
  my $object  = $self->object; 
  return $self->dom->create_element('div', {
    'class'     => $object->content_css,
    'children'  => [
      {'node_name' => 'h2', 'inner_HTML' => sprintf('No %s found', $object->record_name->{'plural'})},
      {'node_name' => 'p',  'inner_HTML' => sprintf('No %s found in the database', $object->record_name->{'plural'}), 'flags' => $self->_FLAG_NO_CONTENT}
    ]
  });
}

sub content_pagination {
  ## Generates HTML for pagination links
  ## @param Number of records being displayed on the page
  ## @return html string
  return shift->content_pagination_tree(@_)->render;
}

sub content_pagination_tree {
  ## Generates and returns a DOM tree of pagination links
  ## @param Number of records being displayed on the page
  ## @return E::W::DOM::Node::Element::Div object
  my ($self, $records_count) = @_;
  
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $page        = $object->get_page_number;
  my $page_count  = $object->get_page_count;
  my $count       = $object->get_count;
  my $offset      = ($page - 1) * $object->pagination;
  my $pagination  = $self->dom->create_element('div', {'class' => 'dbf-pagination _dbf_pagination', 'flags' => 'pagination_div'});
  my $links       = $pagination->append_child($self->dom->create_element('div', {'class' => 'dbf-pagelinks', 'flags' => 'pagination_links'}));

  $page < 1 and $page = 1 or $page > $page_count and $page = $page_count;
  
  my $page_counter = $pagination->prepend_child('p', {
    'class'       => 'dbf-pagecount',
    'flags'       => 'page_counter',
    'inner_HTML'  => sprintf("Page %d of %d (displaying %d - %d  of %d %s)", $page, $page_count, $offset + 1, $offset + $records_count, $count, $object->record_name->{$count == 1 ? 'singular' : 'plural'})
  });

  $links->append_child($self->dom->create_element('a', {
    'href'        => $hub->url({'page' => $page - 1 || 1}, undef, 1),
    'inner_HTML'  => '&laquo; Previous',
    $page == 1 ?
    ('class'      => 'disabled') : (),
  }));
  
  my $pages_needed = { map {$_ => 1} 1, 2, $page_count, $page_count - 1, $page, $page - 1, $page - 2, $page + 1, $page + 2 };
  
  my $previous_num = 0;
  for (sort {$a <=> $b} keys %$pages_needed) {
  
    next if $_ <= 0 || $_ > $page_count;
    for my $num ($_ - $previous_num > 4 ? ($_) : ($previous_num + 1 .. $_)) {
      $num > $previous_num + 1 and $links->append_child($self->dom->create_element('span', {'inner_HTML' => '&#8230;'}));
      $links->append_child($self->dom->create_element('a', {
        'href'        => $hub->url({'page' => $num}, undef, 1),
        'inner_HTML'  => $num,
        $page == $num ?
        ('class'      => 'selected') : ()
      }));
      $previous_num = $num;
    }
    $previous_num = $_;
  }

  $links->append_child($self->dom->create_element('a', {
    'href'        => $hub->url({'page' => $page_count - ($page_count - $page || 1) + 1}, undef, 1),
    'inner_HTML'  => 'Next &raquo;',
    $page == $page_count ?
    ('class'      => 'disabled') : (),
  }));
  
  return $pagination;
}

sub unpack_rose_object {
  ## Converts a rose object, it's columns and relationships into a data structure that can easily be used to display frontend
  ## @param Rose object to be unpacked
  ## @param GET param values to override any value in the object field
  ## @return ArrayRef if E::ORM::Rose::Field objects
  my ($self, $record, $url_params) = @_;

  my $object    = $self->object;
  my $manager   = $object->manager_class;
  $record     ||= $manager->create_empty_object;
  my $meta      = $record->meta;
  my $fields    = $object->get_fields;
  my $relations = { map {$_->name => $_ } $meta->relationships                    };
  my $columns   = { map {$_->name => $_ } $meta->columns, $meta->virtual_columns  };
  my $unpacked  = [];

  while (my $field_name = shift @$fields) {

    my $field           = shift @$fields; # already a hashref with keys that should not be modified (except 'value' if its undef) - keys as accepted by Form->add_field method
    my $value           = exists $url_params->{$field_name} ? $url_params->{$field_name} : $record->field_value($field_name);
    $value              = $field->{'value'} unless defined $value;
    $field->{'value'}   = $value;
    $field->{'name'}  ||= $field_name;

    my $select          = $field->{'type'} && $field->{'type'} =~ /^(dropdown|checklist|radiolist)$/i ? 1 : 0;

    ## if this field is a relationship
    if (exists $relations->{$field_name}) {

      my $relationship              = $relations->{$field_name};
      my $related_object_meta       = $relationship->can('class') ? $relationship->class->meta : $relationship->map_class->meta->relationship($relationship->name)->class->meta;

      my $title_column              = $related_object_meta->column($related_object_meta->title_column);
      $field->{'is_datastructure'}  = $title_column && $title_column->type eq 'datastructure';
      $field->{'value_type'}        = $relationship->type;

      ## get lookup if type is either 'dropdown' or 'checklist' or 'radiolist'
      if ($select) {
        $field->{'value'}     = [];
        $field->{'multiple'}  = $relationship->is_singular ? 0 : 1;
        $field->{'lookup'}    = $manager->get_lookup($related_object_meta->class);
        $field->{'selected'}  = { map {
          !ref $_
            ? exists $field->{'lookup'}{$_}
            ? ($_ => $field->{'lookup'}{$_})
            : ()
            : ($_->get_primary_key_value => $_->get_title)
        } (ref $value eq 'ARRAY'
          ? ( $field->{'multiple'}
            ? @$value
            : shift @$value
          ) : $value
        ) } if $value;
      }
    }

    ## if this field is a column
    elsif (exists $columns->{$field_name}) {
      my $column = $columns->{$field_name};

      $field->{'value_type'}        = 'noedit' if $column->type ne 'virtual' && $column->is_primary_key_member; #force readonly primary key
      $field->{'is_datastructure'}  = $column->type eq 'datastructure';
      $field->{'is_column'}         = 1;

      if (($field->{'value_type'} = $column->type) =~ /^(enum|set)$/ || $select) {

        $field->{'value'}    = [];
        $field->{'lookup'}   = {};
        $field->{'selected'} = {};
        $field->{'multiple'} = $1 eq 'set' ? 1 : 0;

        $value = defined $value ? { map {$_ => 1} (ref $value ? ($field->{'multiple'} ? @$value : shift @$value) : $value) } : {};

        for (@{delete $field->{'values'} || ($column->can('values') ? $column->values : [])}) {
          my $label;
          if (ref $_) {
            $label = $_->{'caption'};
            $_     = $_->{'value'};
          }
          else {
            ($label = ucfirst $_) =~ s/_/ /g;
          }
          $field->{'lookup'}{$_}   = $label;
          $field->{'selected'}{$_} = $label if exists $value->{$_};
        }
      } else {
        $field->{'value'} = shift @$value if ref $value eq 'ARRAY';
      }
    }

    ## if any external relation
    else {
      $field->{'value_type'} = 'one to one';
      $field->{'selected'}   = {$value->get_primary_key_value => $value->get_title} if $value;
    }
    push @$unpacked, EnsEMBL::ORM::Rose::Field->new($field);
  }
  
  return $unpacked;
}

sub print_datetime {
  ## Prints DateTime as a readable string
  return format_date(parse_date($_[1]), "%b %e, %Y at %H:%M");
}

1;
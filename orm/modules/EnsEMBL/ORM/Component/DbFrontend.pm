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
  my $self = shift;
  return $self->dom->create_element('p', {'inner_HTML' => sprintf('No %s found in the database', $self->object->record_name->{'plural'})});
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
  my $pagination  = $self->dom->create_element('div', {'class' => 'dbf-pagination'});
  my $links       = $pagination->append_child($self->dom->create_element('div', {'class' => 'dbf-pagelinks'}));
  $links->set_flag('pagination_links');

  $page < 1 and $page = 1 or $page > $page_count and $page = $page_count;
  
  my $page_counter = $pagination->prepend_child($self->dom->create_element('p', {
    'class'       => 'dbf-pagecount',
    'inner_HTML'  => sprintf("Page %d of %d (displaying %d - %d  of %d %s)", $page, $page_count, $offset + 1, $offset + $records_count, $count, $count == 1 ? $object->record_name->{'singular'} : $object->record_name->{'plural'})
  }));
  $page_counter->set_flag('page_counter');

  my $link_class = $self->modal_link;
  
  $links->append_child($self->dom->create_element('a', {
    'href'        => $hub->url({'page' => $page - 1 || 1}),
    'class'       => join(' ', $page == 1 ? 'disabled' : '', $link_class),
    'inner_HTML'  => '&laquo; Previous',
  }));
  
  my $pages_needed = { map {$_ => 1} 1, 2, $page_count, $page_count - 1, $page, $page - 1, $page - 2, $page + 1, $page + 2 };
  
  my $previous_num = 0;
  for (sort {$a <=> $b} keys %$pages_needed) {
    $_ > $previous_num + 1 and $links->append_child($self->dom->create_element('span', {'inner_HTML' => '&#133;'}));
    $_ > 0 and $_ <= $page_count and $links->append_child($self->dom->create_element('a', {
      'href'        => $hub->url({'page' => $_}),
      'class'       => join(' ', $page == $_ ? 'selected' : '', $link_class),
      'inner_HTML'  => $_,
    }));
    $previous_num = $_;
  }

  $links->append_child($self->dom->create_element('a', {
    'href'        => $hub->url({'page' => $page_count - ($page_count - $page || 1) + 1}),
    'class'       => join(' ', $page == $page_count ? 'disabled' : '', $link_class),
    'inner_HTML'  => 'Next &raquo;',
  }));
  
  return $pagination;
}

sub unpack_rose_object {
  ## Converts a rose object, it's columns and relationships into a data structure that can easily be used to display frontend
  ## @param Rose object to be unpacked
  ## @return ArrayRef if E::ORM::Rose::Field objects
  my ($self, $record) = @_;

  my $object    = $self->object;
  my $manager   = $object->manager_class;
  $record     ||= $manager->create_empty_object;
  my $fields    = $object->show_fields;
  my $relations = { map {$_->name => $_ } @{$manager->get_relationships($record) || []} };
  my $columns   = { map {$_->name => $_ } @{$manager->get_columns($record)       || []} };
  my $unpacked  = [];

  while (my $field_name = shift @$fields) {
  
    my $field = shift @$fields; # already a hashref with keys that should not be modified - keys as accepted by Form->add_field method
    my $value = $field->{'value'} ||= $record->$field_name;
    $field->{'name'} ||= $field_name;
    
    my $select = $field->{'type'} && $field->{'type'} =~ /^(dropdown|checklist|radiolist)$/i ? 1 : 0;

    ## if this field is a relationship
    if (exists $relations->{$field_name}) {
      my $relation = $relations->{$field_name};
      $field->{'value_type'} = $relation->type;
      
      ## get lookup if type is either 'dropdown' or 'checklist' or 'radiolist'
      if ($select) {
        
        my $related_object_class;
        my $ref_value;
        if (!$value || ref $value eq 'ARRAY' && !@$value) {

          if ($relation->can('class')) {
            $related_object_class = $relation->class;
          }
          else {
            $related_object_class = $relation->map_class->meta->relationship($relation->name)->class;
          }
        }
        else {
          $ref_value = ref $value eq 'ARRAY' ? $value->[0] : $value;
          $related_object_class = ref $ref_value;
        }

        if ($ref_value) {
          my $primary_key      = $ref_value->primary_key;
          $field->{'selected'} = ref $value eq 'ARRAY' ? { map {$_->$primary_key => $_->get_title} @$value } : { $value->$primary_key => $value->get_title };
        }

        $field->{'multiple'} = $relation->is_singular ? 0 : 1;
        $field->{'lookup'}   = $manager->get_lookup($related_object_class);
      }
    }

    ## if this field is a column
    elsif (exists $columns->{$field_name}) {
      my $column = $columns->{$field_name};
      $field->{'type'} = 'noedit' if $column->is_primary_key_member; #force readonly primary key

      if (($field->{'value_type'} = $column->type) =~ /^(enum|set)$/ || $select) {
      
        if (defined $value) {
          $value = [ $value ] unless ref $value;
          $value = { map {$_ => 1} @$value };
        }
        else {
          $value = {};
        }
        
        $field->{'lookup'}   = {};
        $field->{'selected'} = {};
        $field->{'multiple'} = $1 eq 'set' ? 1 : 0;

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
      }
    }
    
    ## if any linked user
    else {
      $field->{'value_type'} = 'one to one';
      $field->{'selected'}   = {$value->get_primary_key_value => $value->get_title} if $value;
    }

    push @$unpacked, EnsEMBL::ORM::Rose::Field->new($field);
  }
  
  return $unpacked;
}

sub _modify_trackable_field_params {
  ## Modifies the tracklable field's params hash provided as argument, according to the trackable info
  ## @param HashRef as accepted by Form->add_field method
  ## @param 'by_user' or 'at'
  ## @return HashRef as accepted by Form->add_field method, after some modifications
  my ($self, $param, $type) = @_;
  
  return unless $type;

  if ($type eq 'by_user') {
    my $user = $self->hub->user;
    $param->{'caption'} = $user->name;
    $param->{'value'}   = $user->user_id;
  }
  else {
    $param->{'caption'} = 'Now';
    $param->{'value'}   = parse_date('now');
  }
}

sub print_datetime {
  ## Prints DateTime as a readable string
  return format_date(parse_date($_[1]), "%b %e, %Y at %H:%M");
}

sub modal_link {
  ## returns the class name for a link (according to Object::DbFrontend->page_type)
  ## @param Flag if on, returns 'class="modal_link"' otherwise 'modal_link'
  shift and ($_ and return qq( class="$_" ) or return ' ') or return $_ for (shift->object->page_type eq 'modal' ? 'modal_link' : '');
}

1;

package EnsEMBL::Admin::Component::Changelog::Summary;

### Module to display all declarations for the upcoming release

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub content_tree {
  ## @overrides
  my $self    = shift;
  my $content = $self->SUPER::content_tree;
  my $toc     = $content->prepend_child('div', {'class' => 'cl-toc'});

  $content->prepend_child('h1', {'inner_HTML' => sprintf('Changelog for release %d', $self->object->requested_release)});

  my $teams = [];
  foreach my $team_div (@{$content->get_nodes_by_flag('team_name')}) {
    $team_div->before('h2', {'id' => "team_$_", 'inner_HTML' => $_, 'class' => '_cl_team_heading cl-team-heading'}) and push @$teams, $_ for $team_div->get_flag('team_name');
  }
  $toc->append_child('p', {'inner_HTML' => qq(<a href="#team_$_">$_</a>)}) for sort @$teams;

  return $content;
}

sub record_tree {
  ## @overrides
  my ($self, $record) = @_;
  my $object = $self->object;

  my $record_div  = $self->dom->create_element('div');
  my $primary_key = $record->get_primary_key_value;

  my $team = $record->team;
  $record_div->set_flag('team_name', $self->{'__previous_team'} = $team) if !exists $self->{'__previous_team'} || $self->{'__previous_team'} ne $team;
  
  my @for_logged_in_user = ();
  if ($self->hub->user) {
    @for_logged_in_user = (
      {'node_name' => 'span', 'inner_HTML' => 'Declared by:', 'class' => 'cl-field-title'},
      {'node_name' => 'span', 'inner_HTML' => $self->display_field_value($record->created_by_user), 'class' => 'cl-field-value'},
      {'node_name' => 'span', 'inner_HTML' => 'Last updated:', 'class' => 'cl-field-title'},
      {'node_name' => 'span', 'inner_HTML' => $self->display_field_value($record->modified_at ? $record->modified_at : $record->created_at), 'class' => 'cl-field-value'},
    );
  }

  $record_div->append_children(
    {'node_name' => 'input','class' => '_cl_team_name',   'value'      => $record->team, 'type' => 'hidden'},
    {'node_name' => 'h3',   'class' => 'cl-title',        'inner_HTML' => $record->title},
    {'node_name' => 'div',  'class' => 'cl-title',        'inner_HTML' => $record->content},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Team:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $record->team},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Species:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $self->display_field_value((my $a = $record->species), {'delimiter' => ', '}) || 'All Species'},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Status:'},
    {'node_name' => 'span', 'class' => 'cl-field-value cl-fv-'.$record->status, 'inner_HTML' => $self->display_field_value($record->status)},
    @for_logged_in_user
  );

  $record_div->append_child('div', {
    'class'       => "dbf-row-buttons",
    'inner_HTML'  => scalar @for_logged_in_user ? sprintf(
      '<a href="%s">View</a><a href="%s" class="%s">Edit</a>%s',
      $self->hub->url({'action' => 'Display', 'id' => $primary_key}),
      $self->hub->url({'action' => 'Edit', 'id' => $primary_key}),
      $self->_JS_CLASS_EDIT_BUTTON,
      $object->permit_delete ? sprintf('<a class="%s" href="%s">Delete</a>', $self->_JS_CLASS_EDIT_BUTTON, $self->hub->url({'action' => 'Confirm', 'id' => $primary_key})) : ''
    ) : ''
  });
  return $record_div;

}

1;
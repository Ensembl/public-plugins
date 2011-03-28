package EnsEMBL::Admin::Component::Changelog::Summary;

### Module to display all declarations for the upcoming release

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub content_tree {
  ## @overrides
  my $self    = shift;
  my $dom     = $self->dom;
  my $content = $self->SUPER::content_tree;
  my $toc     = $content->prepend_child($dom->create_element('div', {'class' => 'cl-toc'}));

  $content->prepend_child($dom->create_element('h1', {'inner_HTML' => sprintf('Changelog for release %d', $self->object->requested_release)}));

  for (@{$content->get_nodes_by_flag('team_name')}) {
    my $team = $_->get_flag('team_name');
    $_->before($dom->create_element('h2', {'id' => "team_$team", 'inner_HTML' => $team, 'class' => 'cl-team-heading'}));
    $toc->append_child($dom->create_element('p', {'inner_HTML' => qq(<a href="#team_$team">$team</a>)}));
  }

  $_->remove for @{$content->get_nodes_by_flag('pagination_links')};
  return $content;
}

sub record_tree {
  ## @overrides
  my ($self, $record) = @_;
  my $object = $self->object;
  my $dom    = $self->dom;

  my $record_div  = $dom->create_element('div');
  my $primary_key = $record->get_primary_key_value;

  my $team = $record->team;
  $record_div->set_flag('team_name', $self->{'__previous_team'} = $team) if !exists $self->{'__previous_team'} || $self->{'__previous_team'} ne $team;

  $record_div->append_children(
    $dom->create_element('h3',   {'inner_HTML' => $record->title }),
    $dom->create_element('div',  {'inner_HTML' => $record->content }),
    $dom->create_element('span', {'inner_HTML' => 'Species:', 'class' => 'cl-field-title'}),
    $dom->create_element('span', {'inner_HTML' => $self->display_field_value((my $a = $record->species), ', ') || 'All Species', 'class' => 'cl-field-value'}),
    $dom->create_element('span', {'inner_HTML' => 'Status:', 'class' => 'cl-field-title'}),
    $dom->create_element('span', {'inner_HTML' => $self->display_field_value($record->status), 'class' => 'cl-field-value cl-fv-'.$record->status}),
    $dom->create_element('span', {'inner_HTML' => 'Declared by:', 'class' => 'cl-field-title'}),
    $dom->create_element('span', {'inner_HTML' => $self->display_field_value($record->created_by_user), 'class' => 'cl-field-value'}),
    $dom->create_element('span', {'inner_HTML' => 'Last updated:', 'class' => 'cl-field-title'}),
    $dom->create_element('span', {'inner_HTML' => $self->display_field_value($record->modified_at ? $record->modified_at : $record->created_at), 'class' => 'cl-field-value'}),
  );

  $record_div->append_child($dom->create_element('div', {
    'class'       => "dbf-row-buttons",
    'inner_HTML'  => sprintf(
      '<a href="%s">View</a><a href="%s">Edit</a>%s',
      $self->hub->url({'action' => 'Display', 'id' => $primary_key}),
      $self->hub->url({'action' => 'Edit', 'id' => $primary_key}),
      $object->permit_delete ? sprintf('<a href="%s">Delete</a>', $self->hub->url({'action' => 'Confirm', 'id' => $primary_key})) : ''
    )
  }));
  return $record_div;

}

1;
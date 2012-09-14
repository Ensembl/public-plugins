package EnsEMBL::Admin::Component::Changelog::Summary;

### Module to display all declarations for the upcoming release

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Display);

sub content_tree {
  ## @overrides
  my $self    = shift;
  my $content = $self->SUPER::content_tree;
  my $hub     = $self->hub;
  my $user    = $hub->user;
  my $object  = $self->object;
  my $release = $object->requested_release;
  my $current = $object->current_release;
  my $toc     = $content->prepend_child('div', {'class' => 'cl-toc'});

  if (my $add_button = $content->get_nodes_by_flag('add_new_button')->[0]) {
    if ($user && $user->is_member_of($hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
      $add_button = $add_button->get_elements_by_tag_name('a')->[0];
      if ($release eq $current) {
        $add_button->after({ 'node_name' => 'a', 'inner_HTML' => 'Copy from a previous release', 'href' => $hub->url({'action' => 'ListReleases', 'pull' => 1})});
      }
      else {
        $add_button->before({'node_name' => 'a', 'inner_HTML' => 'View for current release', 'href' => $hub->url({'action' => 'Summary', 'release' => $current})});
      }
    }
    else {
      $add_button->remove;
    }
  }

  $_->remove for @{$content->get_nodes_by_flag(['pagination_div'])};

  $content->prepend_child('h1', {'inner_HTML' => sprintf('Changelog for release %d', $release)});

  my $teams = { map {$_ => {
    'heading' => $self->dom->create_element('h2', {'id' => "team_$_",     'inner_HTML' => $_, 'class' => '_cl_team_heading cl-team-heading'}),
    'link'    => $self->dom->create_element('p',  {'id' => "_cl_link_$_", 'inner_HTML' => qq(<a href="#team_$_">$_</a>)})
  }} @{$object->manager_class->object_class->meta->column('team')->values} };

  $_->before($teams->{$_->get_flag('team_name')}{'heading'}) for @{$content->get_nodes_by_flag('team_name')};
  $toc->append_child($teams->{$_}{'link'}) for sort keys %$teams;

  my $ref_heading;
  for (reverse sort keys %$teams) {
    my $heading = $teams->{$_}{'heading'};
    if (!$heading->parent_node) {
      $ref_heading ? $ref_heading->before($heading) : $content->append_child($heading);
      $_->set_attribute('class', 'hidden') for $heading, $teams->{$_}{'link'};
    }
    $ref_heading = $heading;
  }

  return $content;
}

sub record_tree {
  ## @overrides
  my ($self, $record) = @_;
  my $object      = $self->object;
  my $hub         = $self->hub;
  my $valid_user  = $hub->user;
     $valid_user  = undef unless $valid_user && $valid_user->is_member_of($hub->species_defs->ENSEMBL_WEBADMIN_ID);

  my $record_div  = $self->dom->create_element('div');
  my $padded_div  = $record_div->append_child('div', {'class' => 'cl-padded'});
  my $primary_key = $record->get_primary_key_value;

  my $team        = $record->team;
  $record_div->set_flag('team_name', $self->{'__previous_team'} = $team) unless exists $self->{'__previous_team'} && $self->{'__previous_team'} eq $team;

  $padded_div->append_children(
    {'node_name' => 'input','class' => '_cl_team_name',   'value'      => $team, 'type' => 'hidden'},
    {'node_name' => 'h3',                                 'inner_HTML' => $record->title},
    {'node_name' => 'div',                                'inner_HTML' => $record->content},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Team:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $team},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Species:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $self->display_field_value((my $a = $record->species), {'delimiter' => ', '}) || 'All Species'},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Status:'},
    {'node_name' => 'span', 'class' => 'cl-field-value cl-fv-'.$record->status, 'inner_HTML' => $self->display_field_value($record->status)},
    $valid_user ? (
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Priority:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $self->display_field_value($record->priority, {'lookup' => {@{$object->show_fields}}->{'priority'}->{'values'} })},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Declared by:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $self->display_field_value($record->created_by_user)},
    {'node_name' => 'span', 'class' => 'cl-field-title',  'inner_HTML' => 'Last updated:'},
    {'node_name' => 'span', 'class' => 'cl-field-value',  'inner_HTML' => $self->display_field_value($record->modified_at ? $record->modified_at : $record->created_at)}
    ) : ()
  );

  $record_div->append_child('div', {'class' => 'dbf-row-buttons', 'inner_HTML' => sprintf(
    '<a href="%s">View</a><a href="%s" class="%s">Edit</a>%s',
    $hub->url({'action' => 'Display', 'id' => $primary_key}),
    $hub->url({'action' => 'Edit', 'id' => $primary_key}),
    $self->_JS_CLASS_EDIT_BUTTON,
    $object->permit_delete ? sprintf('<a class="%s" href="%s">Delete</a>', $self->_JS_CLASS_EDIT_BUTTON, $hub->url({'action' => 'Confirm', 'id' => $primary_key})) : ''
  )}) if $valid_user;

  return $record_div;
}

1;
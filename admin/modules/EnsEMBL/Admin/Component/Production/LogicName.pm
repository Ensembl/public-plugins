package EnsEMBL::Admin::Component::Production::LogicName;

use strict;

use base qw(EnsEMBL::Web::Component);

sub caption {
  return '';
}

sub content {
  my $self = shift;
  
  my $object  = $self->object;
  my $dom     = $self->dom;
  my $records = $object->rose_objects;
  my $content = $dom->create_element('div');
  my $table   = $dom->create_element('table', {'class' => 'ss ss_admin'});
  my @widths  = qw(24px 200px 100px 80px 100%);
  $table->append_child($dom->create_element('tr', {'class' => 'ss_header'}))->append_children(
    map {$dom->create_element('td', {'inner_HTML' => $_, 'style' => sprintf('width:%s', shift @widths)})} ('', 'Species', 'Database Type', 'Displayable', 'Web Data')
  );
  
  foreach my $analysis_description (@$records) {
    
    my $id = $analysis_description->get_primary_key_value;
    $content->append_child($dom->create_element('h2',   {'inner_HTML' => sprintf('%s (%s)', $analysis_description->display_label, $analysis_description->logic_name), 'class' => 'prod-h2'}));
    $content->append_child($dom->create_element('div',  {
      'inner_HTML'  => sprintf('<a href="%s">View</a><a href="%s">Edit</a><a href="%s">Link web data</a>',
        $self->hub->url({'action' => 'Display', 'id'      => $id}),
        $self->hub->url({'action' => 'Edit',    'id'      => $id}),
        $self->hub->url({'type'   => 'AnalysisWebdata', 'action'  => 'Add', 'ad' => $id})),
      'class'       => 'dbf-row-buttons'
    }));
    my @bg = qw(bg1 bg2);
    
    my $analysis_web_data = $analysis_description->analysis_web_data;

    if ($analysis_web_data && @$analysis_web_data) {
    
      my $tbl = $content->append_child($table->clone_node(1));
      
      foreach my $awd (@$analysis_web_data) {
      
        $tbl->append_child($dom->create_element('tr', {'class' => [reverse @bg]->[0]}))->append_children(
          map {$dom->create_element('td', {'inner_HTML' => $_})} (
            sprintf('<a href="%s"><img src="/i/edit.gif" height="16" width="16" border="0" title="Click to edit" alt="Edit" /></a>', $self->hub->url({'type' => 'AnalysisWebdata', 'action' => 'Edit', 'id' => $awd->get_primary_key_value})),
            $awd->species  ? $awd->species->db_name : '',
            $awd->db_type,
            $awd->displayable ? 'Yes' : 'No',
            $awd->web_data ? $awd->web_data->data   : ''
          )
        );
      }
    }
    else {
      $content->append_child($dom->create_element('p', {'inner_HTML' => 'There is no web data linked to this analyais description.'}));
    }
  }
  
  return $content->render;
}

1;
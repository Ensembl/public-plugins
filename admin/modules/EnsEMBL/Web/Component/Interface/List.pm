package EnsEMBL::Web::Component::Interface::List;

### Module to create generic record list for Interface and its associated modules

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Interface);
use EnsEMBL::Web::Form;
use EnsEMBL::Web::Document::SpreadSheet;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return $self->object->interface->caption('list') || 'All Records';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $object_type = $ENV{'ENSEMBL_TYPE'};
  my $action = $ENV{'ENSEMBL_ACTION'};
  my $columns = $object->interface->option_columns || $object->interface->element_order;
  my @records;
  warn "TYPE $action";
  if ($action eq 'NewsItem' || $action eq 'Declaration') {
    @records = sort {$a->team cmp $b->team}
      $object->interface->data->search('release_id' => $object->species_defs->ENSEMBL_VERSION);
  }
  else {
    @records = $object->interface->record_list;
  }

  my $table = new EnsEMBL::Web::Document::SpreadSheet( [], [], {'margin' => '0px'} );
  my $width = int(95/scalar(@$columns));
  my $edit_image = '<img src="/i/edit.gif" alt="[Edit]" title="Edit this record" />';
  
  $table->add_columns({ 'key' => 'edit_link', 'title' => 'Edit', 'width' => '5%', 'align' => 'left' });
  foreach my $column (@$columns) {
    $table->add_columns({ 'key' => $column, 'title' => ucfirst($column), 'width' => $width.'%', 'align' => 'left' });
  }
  foreach my $record (@records) {
    next unless $record;
    my $id = $record->id;
    my $url = "/$object_type/";
    if ($object_type eq 'Help') {
      $url .= ucfirst($record->type);
    }
    else {
      $url .= $ENV{'ENSEMBL_ACTION'};
    }
    my $row = {'edit_link' => qq(<a href="$url/Edit?id=$id" class="modal_link">$edit_image</a>)};
    foreach my $column (@$columns) {
      $row->{$column} = $record->$column || '&nbsp;';
    }
    $table->add_row($row);
  }
  
  return $table->render;
}

1;

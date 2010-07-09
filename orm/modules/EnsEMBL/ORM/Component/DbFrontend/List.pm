package EnsEMBL::ORM::Component::DbFrontend::List;

### Module to create generic record list for DbFrontend and its associated modules

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::ORM::Component::DbFrontend);
use EnsEMBL::Web::Form;
use EnsEMBL::Web::Data::User;
use EnsEMBL::Web::Document::SpreadSheet;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'All Records';
}

sub content {
  my $self = shift;
  my $hub = $self->model->hub;
  my $html;

  my $config  = $self->get_frontend_config;
  my $columns = $config->record_table_columns;
  my (@records, $count);

  if ($config->pagination) {
    @records = @{$self->model->object->fetch_by_page($config->pagination)};
    $count = $self->model->object->count;
    $html .= $self->create_pagination($config->pagination, $count);
  }
  else {
    @records = @{$self->model->object->fetch_all};
    $html .= '<p>Total records: '.@records.'</p>';
  }

  my $table = new EnsEMBL::Web::Document::SpreadSheet( [], [], {'margin' => '0px'} );
  $table->add_columns({'key' => 'edit_link', 'title' => 'Edit', 'width' => '10%', 'align' => 'center'});
  my $edit_image = '<img src="/i/edit.gif" alt="[Edit]" title="Edit this record" />';
  my $width = int(90/scalar($columns));
  
  foreach my $column (@$columns) {
    $table->add_columns({ 'key' => $column, 'title' => ucfirst($column), 'width' => $width.'%', 'align' => 'left' });
  }

  foreach my $record (@records) {
    my $id = $record->changelog_id;
    my $row = {'edit_link'        => qq(<a href="/Changelog/Edit?id=$id">$edit_image</a>)};
    foreach my $column (@$columns) {
      next unless $column;
      if ($column eq 'created_by' || $column eq 'modified_by') {
        my $user = EnsEMBL::Web::Data::User->new($record->$column);
        $row->{$column} = $user ? $user->name : '&nbsp;';
      }
      else {
        $row->{$column} = $record->$column || '&nbsp;';
      }
    }
    $table->add_row($row);
  }
  $html .= $table->render;
  
  if ($config->pagination) {
    $html .= $self->create_pagination($config->pagination, $count);
  }

  return $html;
}

1;

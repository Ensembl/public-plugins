package EnsEMBL::Web::Component::Website::Interface::DeclarationList;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Interface);
use EnsEMBL::Web::Form;
use EnsEMBL::Web::Document::SpreadSheet;
use EnsEMBL::Web::Data::NewsItem;
use EnsEMBL::Web::Data::User;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'Declarations for Release '.$self->object->param('release_id');
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $release_id = $object->param('release_id') || $object->species_defs->ENSEMBL_VERSION;
  my @records = EnsEMBL::Web::Data::NewsItem->search('release_id' => $release_id);

  my $table = new EnsEMBL::Web::Document::SpreadSheet( [], [], {'margin' => '0px'} );
  my $edit_image = '<img src="/i/edit.gif" alt="[Edit]" title="Edit this record" />';
  
  $table->add_columns({ 'key' => 'edit',        'title' => 'Edit',        'width' => '5%', 'align' => 'left' });
  $table->add_columns({ 'key' => 'title',       'title' => 'Title',       'width' => '25%', 'align' => 'left' });
  $table->add_columns({ 'key' => 'declaration', 'title' => 'Declaration', 'width' => '40%', 'align' => 'left' });
  $table->add_columns({ 'key' => 'declared_by', 'title' => 'Declared by', 'width' => '20%', 'align' => 'left' });
  $table->add_columns({ 'key' => 'status',      'title' => 'Status',      'width' => '10%', 'align' => 'left' });

  my $id;
  foreach my $record (sort {$a->id <=> $b->id} @records) {
    $id = $record->id;
    my $user = EnsEMBL::Web::Data::User->new($record->created_by); 
    my $row = {
      'edit'        => qq(<a href="/Website/Declaration/Edit?id=$id">$edit_image</a>),
      'title'       => $record->title,
      'declaration' => substr($record->declaration, 0, 200),
      'declared_by' => $user->name,
      'status'      => $record->status,
    };
    $table->add_row($row);
  }
  
  return $table->render;
}

1;

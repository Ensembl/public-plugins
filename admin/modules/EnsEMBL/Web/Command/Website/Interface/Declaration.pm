package EnsEMBL::Web::Command::Website::Interface::Declaration;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::NewsItem;
use EnsEMBL::Web::Data::Species;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = EnsEMBL::Web::Interface->new();

  $data = EnsEMBL::Web::Data::NewsItem->new($object->param('id'));
  $interface->data($data);
  $interface->discover;

  $interface->element('caveat', {'type' => 'Information', 'value' => 'Please do not enter text in all capitals, as it then has to be changed back to normal case for use in the news pages!'});
  $interface->element('dec_blurb', {'type' => 'Information', 'value' => 'IMPORTANT: Please put "internal" information in the Notes field, and try to make the Declaration itself as comprehensible as possible - the Declaration field is exported to an email and sent out to users!'});
  $interface->modify_element('declaration', {'rows' => 20, 'cols' => 80});
  $interface->modify_element('notes', {'rows' => 5, 'cols' => 80});
 
  $interface->modify_element('assembly',        {'select' => 'radio', 'label' => 'New assembly'});
  $interface->modify_element('gene_set',        {'select' => 'radio', 'label' => 'New gene set'});
  $interface->modify_element('repeat_masking',  {'select' => 'radio', 'label' => 'New repeat mask'});
  $interface->modify_element('stable_id_mapping', {'select' => 'radio', 'label' => 'Stable ID mapping needed'});
  $interface->modify_element('affy_mapping',    {'select' => 'radio', 'label' => 'Affy mapping needed'});
  $interface->modify_element('database',        {'select' => 'radio', 'label' => 'Database on ens-staging'});
  $interface->modify_element('release_id', {'type' => 'Hidden', 'value' => $object->species_defs->ENSEMBL_VERSION});


  my $values = [];
  my $species = EnsEMBL::Web::Data::Species->new();
  my @species = $species->species($object->species_defs->ENSEMBL_VERSION);
  foreach my $sp (sort {$a->name cmp $b->name} @species) {
    (my $name = $sp->name) =~ s/_/ /;
    push @$values, {'name' => $name, 'value' => $sp->id},
  }
  my @item_species = $data->species_ids($data->id);

  $interface->element('species', {'type' => 'MultiSelect', 'name' => 'species', 'label' => 'Species (leave blank for "all")', 'values' => $values, 'select' => 'select', 'value' => \@item_species});
  $interface->element_order(['team', 'caveat', 'title', 'dec_blurb', 'declaration', 'notes', 'species', 'assembly', 'gene_set', 'repeat_masking', 'stable_id_mapping', 'affy_mapping', 'database', 'status', 'release_id']);

  $interface->dropdown(1);
  $interface->option_columns(['team','title','declaration']);
  
  $interface->configure($self->webpage, $object);

}

}

1;

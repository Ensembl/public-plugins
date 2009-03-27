package EnsEMBL::Web::Command::Website::Interface::Declaration;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::Data::NewsItem;
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
  $interface->modify_element('declaration', {'rows' => 20, 'cols' => 80});
  $interface->modify_element('notes', {'rows' => 5, 'cols' => 80});

  $interface->modify_element('assembly',        {'select' => 'radio', 'label' => 'New assembly'});
  $interface->modify_element('gene_set',        {'select' => 'radio', 'label' => 'New gene set'});
  $interface->modify_element('repeat_masking',  {'select' => 'radio', 'label' => 'New repeat mask'});
  $interface->modify_element('stable_id_mapping', {'select' => 'radio', 'label' => 'Stable ID mapping needed'});
  $interface->modify_element('affy_mapping',    {'select' => 'radio', 'label' => 'Affy mapping needed'});
  $interface->modify_element('database',        {'select' => 'radio', 'label' => 'Database on ens-staging'});

  $interface->element_order(['team', 'title', 'caveat', 'declaration', 'species', 'notes', 'assembly', 'gene_set', 'repeat_masking', 'stable_id_mapping', 'affy_mapping', 'database', 'status']);
  $interface->dropdown(1);
  $interface->option_columns(['team','declaration']);

  $interface->configure($self->webpage, $object);

}

}

1;

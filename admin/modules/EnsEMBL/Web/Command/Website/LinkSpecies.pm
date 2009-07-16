package EnsEMBL::Web::Command::Website::LinkSpecies;

### Custom save module to create many-to-many items between news items and species

use strict;
use warnings;

use EnsEMBL::Web::Data::NewsItem;
use EnsEMBL::Web::Data::ItemSpecies;
use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url = '/Website/Declaration/List';
  my $param = {};
 
  ## Then add species to item_species table 
  my @species_ids = ($object->param('species_id'));
  my $item = EnsEMBL::Web::Data::NewsItem->new($object->param('news_item_id'));
  foreach my $id (@species_ids) {
    next if $id =~ /\D/ || !$id;
    $item->add_to_species({'species_id'=>$id});
  }
  $item->save;
  $self->ajax_redirect($url, $param); 
}

}

1;

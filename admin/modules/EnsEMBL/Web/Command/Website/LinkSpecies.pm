package EnsEMBL::Web::Command::Website::LinkSpecies;

### Custom save module to create many-to-many items between news items and species

use strict;
use warnings;

use EnsEMBL::Web::Data::NewsItem;
use EnsEMBL::Web::Data::ItemSpecies;
use base 'EnsEMBL::Web::Command';
use Data::Dumper;

{

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url = '/Website/Declaration/List';
  my $param = {};

  my @ids;
  if ($object->param('species_id')) {
    @ids = ($object->param('species_id'));
  }
  elsif ($object->param('species')) {
    @ids = ($object->param('species'));
  }

  if (scalar(@ids)) {
    my $item = EnsEMBL::Web::Data::NewsItem->new($object->param('id'));

    ## Delete any existing species
    $item->species->delete_all;
 
    ## Then add species to item_species table 
    foreach my $id (@ids) {
      next if $id =~ /\D/ || !$id;
      $item->add_to_species({'species_id'=>$id});
    }
    $item->save;
  }

  $self->ajax_redirect($url, $param); 
}

}

1;

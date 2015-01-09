=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Document::HTML::Compara::SpeciesTree;

## Provides content for compara gene-trees documentation
## Base class - does not itself output content

use strict;

use List::Util qw(min max sum);
use List::MoreUtils qw(uniq);

use HTML::Entities qw(encode_entities);
use JSON qw(to_json);

use Bio::EnsEMBL::Compara::Utils::SpeciesTree;

use base qw(EnsEMBL::Web::Document::HTML::Compara);

sub render {
  my $self  = shift;
  
  my ($tree_details, %species_info);
  
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $compara_db        = $self->hub->database('compara');
  my $genomeDBAdaptor   = $compara_db->get_GenomeDBAdaptor();
  my $ncbiTaxonAdaptor  = $compara_db->get_NCBITaxonAdaptor();
  my $format            = '%{^n}:%{d}';
  
  # Getting the different NCBI trees 
  my $ncbi_species_tree         = Bio::EnsEMBL::Compara::Utils::SpeciesTree->create_species_tree(-compara_dba =>$compara_db); 
  $tree_details->{'ncbi_tree'}  = $ncbi_species_tree->newick_format('ryo', $format); #full tree

# my $spTreeAdaptor = $compara_db->get_SpeciesTreeAdaptor();
# my $format = '%{^n}:%{d}';

# Ensembl (Binary) species tree 
# my $ensembl_sp_tree = $spTreeAdaptor->fetch_by_method_link_species_set_id_label(40098, "default"); #warn "EnsEMBL (Binary) Tree:\n"; warn $ensembl_sp_tree->root()->newick_format('ryo', $format), "\n\n\n";

# my $ensembl_mammal_node = $ensembl_sp_tree->root()->find_node_by_name("Mammalia");
# warn "Ensembl (Binary) Mammals tree:\n"; warn $ensembl_mammal_node->newick_format('ryo', $format), "\n\n";

# my $ensembl_sauria_node = $ensembl_sp_tree->root()->find_node_by_name("Sauria");
# warn "Ensembl (Binary) Sauropsids tree:\n"; warn $ensembl_sauria_node->newick_format('ryo', $format), "\n\n";

# my $ensembl_amniota_node =$ensembl_sp_tree->root()->find_node_by_name("Amniota");
# warn "Ensembl (Binary) Amniota tree:\n"; warn $ensembl_amniota_node->newick_format('ryo', $format), "\n\n";

# my $ensembl_fish_node = $ensembl_sp_tree->root()->find_node_by_name("Neopterygii");
# warn "Ensembl (Binary) Fish tree:\n"; warn $ensembl_fish_node->newick_format('ryo', $format), "\n\n\n";


  # Hardcoded the newick tree details for now until compara has an API and db ready for this (ncbi tree is already available via API)
  $tree_details->{'newick_tree'} = "(((Caenorhabditis elegans:1,Drosophila melanogaster:1)Ecdysozoa:1,((((((((((((((((((((Pan troglodytes:1,Homo sapiens:1)Homininae:1,Gorilla gorilla gorilla:1)Homininae:1,Pongo abelii:1)Hominidae:1,Nomascus leucogenys:1)Hominoidea:1,((Papio anubis:1,Macaca mulatta:1)Cercopithecinae:1,Chlorocebus sabaeus:1)Cercopithecinae:1)Catarrhini:1,Callithrix jacchus:1)Simiiformes:1,Tarsius syrichta:1)Haplorrhini:1,(Microcebus murinus:1,Otolemur garnettii:1)Strepsirrhini:1)Primates:1,Tupaia belangeri:1)Euarchontoglires:1,((Oryctolagus cuniculus:1,Ochotona princeps:1)Lagomorpha:1,((((Rattus norvegicus:1,Mus musculus:1)Murinae:1,Dipodomys ordii:1)Sciurognathi:1,Ictidomys tridecemlineatus:1)Sciurognathi:1,Cavia porcellus:1)Rodentia:1)Glires:1)Euarchontoglires:1,((Erinaceus europaeus:1,Sorex araneus:1)Insectivora:1,(((Pteropus vampyrus:1,Myotis lucifugus:1)Chiroptera:1,((((Mustela putorius furo:1,Ailuropoda melanoleuca:1)Caniformia:1,Canis lupus familiaris:1)Caniformia:1,Felis catus:1)Carnivora:1,Equus caballus:1)Laurasiatheria:1)Laurasiatheria:1,((((Bos taurus:1,Ovis aries:1)Bovidae:1,Tursiops truncatus:1)Cetartiodactyla:1,Vicugna pacos:1)Cetartiodactyla:1,Sus scrofa:1)Cetartiodactyla:1)Laurasiatheria:1)Laurasiatheria:1)Boreoeutheria:1,(((Loxodonta africana:1,Procavia capensis:1)Afrotheria:1,Echinops telfairi:1)Afrotheria:1,(Dasypus novemcinctus:1,Choloepus hoffmanni:1)Xenarthra:1)Eutheria:1)Eutheria:1,((Macropus eugenii:1,Sarcophilus harrisii:1)Marsupialia:1,Monodelphis domestica:1)Marsupialia:1)Theria:1,Ornithorhynchus anatinus:1)Mammalia:1,((((Taeniopygia guttata:1,Ficedula albicollis:1)Passeriformes:1,((Meleagris gallopavo:1,Gallus gallus:1)Phasianidae:1,Anas platyrhynchos:1)Galloanserae:1)Neognathae:1,Pelodiscus sinensis:1)Testudines + Archosauria group:1,Anolis carolinensis:1)Sauria:1)Amniota:1,Xenopus tropicalis:1)Tetrapoda:1,Latimeria chalumnae:1)Sarcopterygii:1,((((((((Xiphophorus maculatus:1,Poecilia formosa:1)Poeciliinae:1,Oryzias latipes:1)Atherinomorphae:1,Gasterosteus aculeatus:1)Percomorphaceae:1,Oreochromis niloticus:1)Percomorphaceae:1,(Takifugu rubripes:1,Tetraodon nigroviridis:1)Tetraodontidae:1)Percomorphaceae:1,Gadus morhua:1)Acanthomorphata:1,(Danio rerio:1,Astyanax mexicanus:1)Otophysa:1)Clupeocephala:1,Lepisosteus oculatus:1)Neopterygii:1)Euteleostomi:1,Petromyzon marinus:1)Vertebrata:1,(Ciona savignyi:1,Ciona intestinalis:1)Ciona:1)Chordata:1)Bilateria:1,Saccharomyces cerevisiae:1):0;";
 
  for my $species (@{$ncbi_species_tree->get_all_nodes()}) {
     my $ncbi_taxon = $ncbiTaxonAdaptor->fetch_node_by_name($species->name);

     my $sp = {};
     $sp->{taxon_id} = $ncbi_taxon->taxon_id();
     $sp->{name}     = $ncbi_taxon->common_name();
     $sp->{timetree} = $ncbi_taxon->get_tagvalue('ensembl timetree mya');
     $sp->{ensembl_name} = $ncbi_taxon->ensembl_alias_name();

     my $genomeDB =$genomeDBAdaptor->fetch_by_taxon_id($ncbi_taxon->taxon_id());
     if (defined $genomeDB) {
         $sp->{assembly} = $genomeDB->assembly;
         $sp->{production_name} = ucfirst($genomeDB->name);
     }
     $species_info{$species->name} = $sp; 
  }
  $tree_details->{'species_tooltip'} = \%species_info;
  
  my $json_info = to_json($tree_details);
 
  my $html = qq{    
    <div  class="js_tree ajax js_panel image_container ui-resizable" id="species_tree" class="widget-toolbar"></div>
    <script>  
      if(!document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.1")) {
        document.getElementById("species_tree").innerHTML = "<div class='error'><h3>Browser Compatibility Issue</h3><div class='message-pad'><p>Your Browser doesn't support the new view, download the static image in PDF using the link above.</p></div></div>";
      } else {
        window.onload = function() {
          Ensembl.SpeciesTree.displayTree($json_info);
        };
      }
    </script>
  };
  
  return $html;
}

1;

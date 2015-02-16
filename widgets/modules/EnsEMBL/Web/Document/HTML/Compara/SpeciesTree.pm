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
  my $species_tree_adaptor = $compara_db->get_SpeciesTreeAdaptor();
  my $mlss_adaptor      = $compara_db->get_MethodLinkSpeciesSetAdaptor();
  my $format            = '%{^n}:%{d}';
  
  my $mlss              = $mlss_adaptor->fetch_by_method_link_type_species_set_name('SPECIES_TREE', 'collection-ensembl');
  # Getting the different NCBI trees 
  my $ncbi_species_tree         = $species_tree_adaptor->fetch_by_method_link_species_set_id_label($mlss->dbID, 'ncbi')->root;
  $tree_details->{'ncbi_tree'}  = $ncbi_species_tree->newick_format('ryo', $format); #full tree

  # Hardcoded the newick tree details for now until compara has an API and db ready for this (ncbi tree is already available via API)
  my $ensembl_species_tree      = $species_tree_adaptor->fetch_by_method_link_species_set_id_label($mlss->dbID, 'ensembl')->root;
  $tree_details->{'newick_tree'} = $ensembl_species_tree->newick_format('ryo', $format);
 
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

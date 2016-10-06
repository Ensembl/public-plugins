=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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
  my $all_trees         = $species_tree_adaptor->fetch_all_by_method_link_species_set_id_label_pattern($mlss->dbID, '');

  # Put all the trees from the database
  # Each tree has a unique key based on its root_id
  # The label is displayed in the menu and in the image heading
  $tree_details->{'trees'} = {};
  foreach my $tree (@$all_trees) {
      $tree_details->{'trees'}->{"t".$tree->root_id()} = {
          'label'   => $tree->label(),
          'newick'  => $tree->root->newick_format('ryo', $format)
      };
  }

  # The filters, e.g. 'Mammalia' => 'mammals (all kinds)'
  # Filters are defined as MLSS tags like 'filter:Mammalia'
  $tree_details->{'filters'} = {};
  foreach my $tag ($mlss->get_all_tags()) {
      if ($tag =~ m/^filter:(.*)$/) {
          $tree_details->{'filters'}->{ucfirst $1} = $mlss->get_value_for_tag($tag);
      }
  }

  # Which tree should be displayed by default (just pick a random one otherwise)
  $tree_details->{'default_tree'} = $mlss->has_tag('default_tree') ? $mlss->get_value_for_tag('default_tree') : (keys %{$tree_details->{'trees'}})[0];
 
  # Go through all the nodes of all the trees and get the tooltip info
  foreach my $tree (@$all_trees) {
   for my $species (@{$tree->root->get_all_nodes()}) {
     next if $species_info{$species->name};
     my $ncbi_taxon = $species->taxon();

     my $sp = {};
     $sp->{taxon_id} = $ncbi_taxon->taxon_id();
     $sp->{name}     = $ncbi_taxon->common_name();
     $sp->{timetree} = $ncbi_taxon->get_tagvalue('ensembl timetree mya');
     $sp->{ensembl_name} = $ncbi_taxon->ensembl_alias_name();

     #hack for 86, need to remove once they have this set in the database
     if($species->name eq 'Mus musculus') {
      $sp->{has_strain}    = 1;
      $sp->{production_name} = "Mus_musculus";
      $sp->{assembly}        = $hub->species_defs->get_config("Mus_musculus", "ASSEMBLY_VERSION");
     }

     my $genomeDB = $species->genome_db();
     if (defined $genomeDB) {
        my $url_name           = $hub->species_defs->production_name_mapping($genomeDB->name);
        $sp->{assembly}        = $genomeDB->assembly;
        $sp->{production_name} = $url_name;
        $sp->{is_strain}       = $hub->species_defs->get_config($url_name, 'IS_STRAIN_OF');
     }
     $species_info{$species->name} = $sp; 
    }
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

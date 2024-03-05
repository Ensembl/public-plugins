=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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
use MIME::Base64;
use EnsEMBL::Web::File::Utils::IO qw/file_exists read_file/;

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
  
  my $mlss              = $mlss_adaptor->fetch_by_method_link_type_species_set_name('SPECIES_TREE', 'collection-vertebrates');
  my $all_trees         = $species_tree_adaptor->fetch_all_by_method_link_species_set_id($mlss->dbID);
  my $pics_path         = "/i/species/48/";

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

  $tree_details->{'filters'} = {};
  my %filters_with_strains;
  my %taxon_id_to_collapse;
  foreach my $tag ($mlss->get_all_tags()) {
      if ($tag =~ m/^filter:str:(.*)$/) {
          # Filter with expanded strains tags are like 'filter:str:Murinae' -> 'Rat and all mice (incl. strains)'
          $tree_details->{'filters'}->{ucfirst $1} = $mlss->get_value_for_tag($tag);
          $filters_with_strains{ucfirst $1} = 1;

      } elsif ($tag =~ m/^filter:(.*)$/) {
          # Filter tags are like 'filter:Mammalia' -> 'Mammals (all kinds)'
          $tree_details->{'filters'}->{ucfirst $1} = $mlss->get_value_for_tag($tag);

      } elsif ($tag =~ m/^ref_genome:(.*)$/) {
          # Reference genome tags are like 'ref_genome:10090' -> 'mus_musculus'
          $taxon_id_to_collapse{$1} = $mlss->get_value_for_tag($tag);
      }
  }

  # Which tree should be displayed by default (just pick a random one otherwise)
  $tree_details->{'default_tree'} = $mlss->has_tag('default_tree') ? $mlss->get_value_for_tag('default_tree') : (keys %{$tree_details->{'trees'}})[0];
 
  # Go through all the nodes of all the trees and get the tooltip info
  my $lookup = $hub->species_defs->prodnames_to_urls_lookup;
  foreach my $tree (@$all_trees) {
   my %ref_genome_2_internal_info;
   for my $species (@{$tree->root->get_all_nodes()}) {
    #  next if $species_info{$species->name}; # $species->name is the name used by newick_format() above

     my $sp = {};
     $sp->{taxon_id} = $species->taxon_id();
     ($sp->{name}     = $species->name()) =~ s/\(|\)//g;  ## Not needed by the Ensembl widget, but required by the underlying TnT library. Should probably be unique
     $sp->{timetree} = $species->get_divergence_time();
     $sp->{ensembl_name} = $species->get_common_name();

     my $genomeDB = $species->genome_db();
     if (defined $genomeDB) {
        my $url_name           = $lookup->{$genomeDB->name};
        $sp->{assembly}        = $genomeDB->assembly;
        $sp->{production_name} = $url_name;
        $sp->{is_strain}       = $hub->species_defs->get_config($url_name, 'IS_STRAIN_OF');
     }

     if ($sp->{production_name}) {
        my $sp_icon = $species_defs->ENSEMBL_WEBROOT . '/../public-plugins/ensembl/htdocs/i/species/' . $sp->{production_name} . '.png';
        if (file_exists($sp_icon, {'no_exception' => 1})) {
          my $content = read_file($sp_icon);
          if ($content) {
            $sp->{icon} = 'data:image/png;base64,'.encode_base64($content);
          }
        }
        else {
          $sp->{icon} = '/i/species/' . $sp->{production_name} . '.png';
        }
      }
     $species_info{$sp->{name}} = $sp;

     # Deal with reference genomes
     # 1. We need to keep a reference to the internal nodes that will be collapsed
     if (my $genome_db_name = $taxon_id_to_collapse{$species->taxon_id}) {
         # Since $tree->root->get_all_nodes() traverses the tree in a
         # pre-order depth-first fashion, we'll find first the deepest node
         unless ($ref_genome_2_internal_info{$genome_db_name}) {
             $ref_genome_2_internal_info{$genome_db_name} = $sp;
         }
     }
     # 2. We then Copy all the info from the reference genome to the internal node
     if ($genomeDB and (my $target_sp = $ref_genome_2_internal_info{$genomeDB->name})) {
         foreach my $k (qw(assembly production_name icon)) {
             $target_sp->{$k} = $sp->{$k} if $sp->{$k};
         }
         $target_sp->{has_strain} = 1;
     }
     if ($filters_with_strains{$sp->{name}}) {
        $sp->{expand_strains} = 1;
     }
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

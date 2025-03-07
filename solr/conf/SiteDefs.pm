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

use strict;

package EnsEMBL::Solr::SiteDefs;
sub update_conf {
  $SiteDefs::OBJECT_TO_CONTROLLER_MAP->{'Search'} = "Page";

  $SiteDefs::ENSEMBL_SOLR_ENDPOINT = ''; # End point fot the SOLR server
  $SiteDefs::ENSEMBL_SOLR_FAILFOR = 600;
  $SiteDefs::SOLR_NO_PROXY = 1;
  $SiteDefs::SOLR_MIRRORS = [];

  $SiteDefs::ENSEMBL_SOLR_CONFIG = defer {{
    ui => {
      #######################
      # PAGES, COLUMNS, etc #
      #######################
      pagesizes => [10,25,50,100],
      downloadmaxrows => 1000,
      downloadfilename => "output",

      ############
      # FACETING #
      ############
      current_facets_heading => "Current selection:",
      facets => [
        {
          key => "species",
          trunc => 6,
          heading => "Restrict species to:",
          text => {
            singular => "species",
            plural => "species",
            a_an => "a"
          },
          filter => "reference_strain:1",
          members => [],
          fav_order => "species", # use these favourites to order
          more => "... ## more species ...",
          less => "show fewer species",
        }, 
        {
          key => "feature_type",
          trunc => 10, # No. entries to display before folding LHS
          text => {
            singular => "category",
            plural => "categories",
          },
          heading => "Restrict category to:",
          more => "... ## more categories ...",
          less => "show fewer categories",
          # If defined here, these values will take priority, over
          # anything coming from SOLR. Also defines order.
          members  => [
            {
              key => 'Gene'
            }, {
              key => 'Transcript'
            }, {
              key => 'Variant'
            }, {
              key => 'Phenotype'
            }, {
              key => 'StructuralVariation'
            }, {
              key => 'Somatic Mutation'
            }, {
              key => 'Family',
              text => {
                singular => "Protein Family",
                plural => "Protein Families",
              },
            }, {
              key => 'GeneTree',
            }, {
              key => 'GenomicAlignment',
            }, {
              key => 'Translation',
            }, {
              key => 'Domain',
              text => {
                singular => "Protein Domain",
                plural => "Protein Domains",
              },
            }, {
              key => 'Sequence',
              text => {
                singular => "Clones & Regions",
                plural => "Clones & Regions",
                a_an => '_uncountable', 
              },
            }, {
              key => 'Marker',
            }, {
              key => 'ProbeFeature',
            }, {
              key => 'RegulatoryFeature',
            }, {
              key => 'Documentation',
              text => {
                singular => 'Help & Docs',
                plural => 'Help & Docs',
                a_an => '_uncountable',
              },
            }
          ],
        },
        {
          key => "strain",
          trunc => 6,
          heading => "Restrict __strain_type__s to:",
          text => {
            singular => "__strain_type__",
            plural => "__strain_type__s",
            a_an => "a"
          },
          members => [],
          more => "... ## more __strain_type__s ...",
          less => "show fewer __strain_type__s",
          reorder => ['reference'],
        }
      ],

      facets_sidebar_order => [
        "feature_type",
        "species",
        "strain"
      ],

      facets_sidebar_deps => {
        strain => { "species" => [
          "Atlantic cod",
          "Atlantic salmon",
          "Chicken",
          "Dog",
          "Domestic cat",
          "Domestic pig",
          "Eastern European house mouse",
          "Goat",
          "House mouse",
          "Japanese wild mouse",
          "Norway rat",
          "Pig",
          "Sheep",
          "Southeastern Asian house mouse",
          "Three-spined stickleback",
          "Western European house mouse"
        ] }
      },

      strain_type  => {
        "Atlantic cod" => "strain",
        "Atlantic salmon" => "strain",
        "Chicken" => "breed",
        "Dog"     => "breed",
        "Domestic cat" => "breed",
        "Domestic pig" => "breed",
        "Eastern European house mouse" => "strain",
        "Goat"    => "breed",
        "House mouse"   => "strain",
        "Japanese wild mouse"   => "strain",
        "Norway rat"     => "strain",
        "Pig"     => "breed",
        "Sheep"   => "breed",
        "Southeastern Asian house mouse"   => "strain",
        "Three-spined stickleback" => "strain",
        "Western European house mouse"   => "strain"
      },

      #######################
      # RESULT HIGHLIGHTING #
      #######################
      hl_transfers => { content => 'description' },
      highlights => ['description','_hr','content'], # fields to highlight

      #######################
      # !xxx type shortcuts #
      #######################

      ddg_codes => {
        facet_feature_type => {
          g => 'Gene',
          t => 'Transcript',
          rf => 'RegulatoryFeature',
          doc => 'Documentation',
          ph => 'Phenotype',
          sm => 'SomaticMutation',
          sv => 'StructuralVariation',
          v => 'Variant',
          dom => 'Domain',
          fam => 'Family',
          pf => 'ProteinFamily',
          m => 'Marker',
          s => 'Sequence',
          ga => 'GenomicAlignment',
          pf => 'ProbeFeature',
        },
        facet_species => {
          hs => 'Human',
          mm => 'Mouse',
          dr => 'Zebrafish',
          rn => 'Rat'
        }
      },

      # ZZZ how is this used in standard view?
      # ZZZ rename all_columns and columns
      ######################
      # COLUMNS TO DISPLAY #
      ######################
      all_columns => [
        { key => 'id_with_url', name => 'ID', width => 10, nosort => 1 },
        { key => 'name', name => 'Name', width => 10, nosort => 1 },
        { key => 'location', name => 'Location', width => 10, nosort => 1 },
        { key => 'species', name => 'Species', width => 10 },
        { key => 'feature_type', name => 'Category', width => 10 },
        { key => 'description', name => 'Description', width => 40, nosort => 1 },
        { key => 'url', name => 'URL', width => 30, nosort => 1 },
        { key => 'score', name => 'Score', width => 10, nosort => 1 },
      ],
      columns => [
        'id_with_url','name','species','feature_type','description'
      ],


      ###############
      # MISC LAYOUT #
      ###############
      enable_direct => 1,
      direct_pause => [700,2000], # since [stopped-typing,last-request] ms
      per_page => 10, # default results per page
      topright_fix => 1, # specific to ensembl
      tips => [
        "
        You can use wildcards in your searches.
        <tt>RHO*</tt> would match RHO, RHOC
            (RHO + zero or more characters); <tt>RHO?</tt> would match 
            RHOC, RHOB (RHO + one character)
        ","
          Help and Documentation can be searched from the homepage!
          Just type in a term you want to know more about, like
          non-synonymous SNP.
        ","
           You can choose which results appear near the top of your
            search by updating your favourite species.
        "
      ],
      mirrors => $SiteDefs::SOLR_MIRRORS || [],
      noresults_help => <<EOF,
        <div>
          <p><b>
            If you think this outcome is an error, please
            contact our
            <a href="/Help/Contact">helpdesk</a>.
          </b></p>
          <table>
            <tr>
              <th colspan="2">You can search by</th>
              <th>Example</th>
            </tr>
            <tr>
              <th colspan="2">Help phrase</th>
              <td>SNP, BioMart, Illumina, COSMIC, API</td>
            </tr>
            <tr>
              <th colspan="2">Gene name</th>
              <td>Rhodopsin, titin, insulin, ...</td>
            </tr>
            <tr>
              <th colspan="2">Gene symbol</th>
              <td>RHO, MAP4K1, FOXP2, ...</td>
            </tr>
            <tr>
              <th rowspan="4" style="width: 20%">Accession Numbers</th>
              <th>UniProt ID</td>
              <td>OPSD_HUMAN, INS_HUMAN, UBB_CAVPO, ...</th>
            </tr>
            <tr>
              <th>NCBI RefSeq</td>
              <td>NP_000530.1, NP_999386.1, ...</th>
            </tr>
            <tr>
              <th>Variant ID</td>
              <td>rs1333049, COSM139481, ...</th>
            </tr>
            <tr>
              <th>etc</td>
              <td>CCDS3063, craHsap1, ...</th>
            </tr>
            <tr>
              <th colspan="2">Phenotype or disease</th>
              <td>glaucoma, osteoporosis, milking speed, ...</td>
            </tr>
            <tr>
              <th colspan="2">Chromosomal region</th>
              <td>human 3:129247483-129254012</td>
            </tr>
          </table>
          <table>
            <tr>
              <th>Syntax</th>
              <th>Effect</th>
            </tr>
            <tr>
              <td>RHO*, INS*</td>
              <td>zero or more additional characters</td>
            </tr>
            <tr>
              <td>FOXP?, TTN?</td>
              <td>one additional character</td>
            </tr>
          </table>
          <p><b>
            A searchbox appears at the top right of every page, and
            on the Ensembl homepage, where you can search help and
            other documentation.
          </b></p>
        </div>
EOF


      ###############
      # QUICK LINKS #
      ###############
      links => [
        { title => "Variant table",
          url => "/{url1}/Gene/Variation_Gene/Table?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Phenotypes",
          url => "/{url1}/Gene/Phenotype?g={id};db={database_type}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Location",
          url => "/{url1}/Location/View?r={location};g={id};db={database_type}",
          conditions => { "{location}" => ".+" }
        },
        { title => "External Refs.",
          url => "/{url1}/Gene/Matches?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "External Refs.",
          url => "/{url1}/Transcript/Similarity?t={id}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Regulation",
          url => "/{url1}/Gene/Regulation?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Orthologues",
          url => "/{url1}/Gene/Compara_Ortholog?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Gene tree",
          url => "/{url1}/Gene/Compara_Tree?db={database_type};g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Genomic Context",
          url => "/{url1}/Variation/Context?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Genomic Context",
          url => "/{url1}/StructuralVariation/Context?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" },
          result_condition_not => 'all:0',
        },
        { title => "Genes",
          url => "/{url1}/Variation/Mappings?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Genes",
          url => "/{url1}/StructuralVariation/Mappings?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" },
          result_condition_not => 'all:0',
        },
        { title => "Evidence",
          url => "/{url1}/StructuralVariation/Evidence?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" },
          result_condition_not => 'all:0',
        },
        { title => "Population",
          url => "/{url1}/Variation/Population?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Individuals",
          url => "/{url1}/Variation/Individual?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "LD",
          url => "/{url1}/Variation/HighLD?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Phenotype",
          url => "/{url1}/Variation/Phenotype?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Phenotype",
          url => "/{url1}/StructuralVariation/Phenotype?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" },
          result_condition_not => 'all:0',
        },
        { title => "Phylogenetics",
          url => "/{url1}/Variation/Compara_Alignments?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "Sequence",
          url => "/{url1}/Variation/Sequence?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" },
          result_condition_not => 'all:0',
        },
        { title => "cDNA seq.",
          url => "/{url1}/Transcript/Sequence_cDNA?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Exons",
          url => "/{url1}/Transcript/Exons?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Variant table",
          url => "/{url1}/Transcript/Variation_Transcript/Table?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Protein seq.",
          url => "/{url1}/Transcript/Sequence_Protein?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" },
          result_condition => 'protein:1',
        },
        { title => "Population",
          url => "/{url1}/Transcript/Population?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Protein summary",
          url => "/{url1}/Transcript/ProteinSummary?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" },
          result_condition => 'protein:1',
        },
        { title => "Sequence",
          url => "/{url1}/LRG/Sequences?lrg={id}",
          conditions => { "{feature_type}" => "^Sequence\$",
                          "{id}" => "^LRG_" },
        },
        { title => "Reference Comparison",
          url => "/{url1}/LRG/Differences?lrg={id}",
          conditions => { "{feature_type}" => "^Sequence\$",
                          "{id}" => "^LRG_" },
        },
      ],
    },
  }};
}
1;


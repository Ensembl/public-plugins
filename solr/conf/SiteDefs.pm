use strict;

package EnsEMBL::Solr::SiteDefs;
sub update_conf {
#  $SiteDefs::ENSEMBL_SOLR_ENDPOINT = "http://solr-slave-ensembl-odd.sanger.ac.uk/solr-sanger/ensembl_core/ensemblshards";
#  $SiteDefs::ENSEMBL_SOLR_ENDPOINT = "http://ec2-50-19-198-203.compute-1.amazonaws.com:8000/solr-sanger/ensembl_core/ensemblshards";
  $SiteDefs::OBJECT_TO_SCRIPT->{'Search'} = "AltPage";

  $SiteDefs::ENSEMBL_SOLR_CONFIG = {
    ui => {
      #######################
      # PAGES, COLUMNS, etc #
      #######################
      pagesizes => [10,25,50,100,0],
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
          members => [],
          fav_order => "species", # use these favourites to order
          more => "... ## more species ...",
          less => "show fewer species",
        }, {
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
              key => 'Variation'
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
      ],

      facets_sidebar_order => [
        "feature_type",
        "species",
      ],

      #######################
      # RESULT HIGHLIGHTING #
      #######################
      highlights => ['description'], # fields to highlight

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
      enable_direct => 0,
      per_page => 10, # default results per page
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
        { title => "Variation table",
          url => "/{species}/Gene/Variation_Gene/Table?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Location",
          url => "/{species}/Location/View?r={location};g={id};db={database_type}",
          conditions => { "{location}" => ".+" }
        },
        { title => "Regulation",
          url => "/{species}/Gene/Regulation?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Orthologues",
          url => "/{species}/Gene/Compara_Ortholog?g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Gene tree",
          url => "/{species}/Gene/Compara_Tree?db={database_type};g={id}",
          conditions => { "{feature_type}" => "^Gene\$" }
        },
        { title => "Genomic Context",
          url => "/{species}/Variation/Context?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Genomic Context",
          url => "/{species}/StructuralVariation/Context?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" }
        },
        { title => "Genes",
          url => "/{species}/Variation/Mappings?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Genes",
          url => "/{species}/StructuralVariation/Mappings?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" }
        },
        { title => "Evidence",
          url => "/{species}/StructuralVariation/Evidence?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" }
        },
        { title => "Population",
          url => "/{species}/Variation/Population?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Individuals",
          url => "/{species}/Variation/Individual?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "LD",
          url => "/{species}/Variation/HighLD?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Phenotype",
          url => "/{species}/Variation/Phenotype?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Phenotype",
          url => "/{species}/StructuralVariation/Phenotype?sv={id};db={database_type}",
          conditions => { "{feature_type}" => "^StructuralVariation\$" }
        },
        { title => "Phylogenetics",
          url => "/{species}/Variation/Compara_Alignments?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "Sequence",
          url => "/{species}/Variation/Sequence?v={id}",
          conditions => { "{feature_type}" => "^(Variation|Somatic Mutation)\$" }
        },
        { title => "cDNA seq.",
          url => "/{species}/Transcript/Sequence_cDNA?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Protein seq.",
          url => "/{species}/Transcript/Variation_Transcript/Table?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Population",
          url => "/{species}/Transcript/Population?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Protein",
          url => "/{species}/Transcript/ProteinSummary?t={id}&db={database_type}",
          conditions => { "{feature_type}" => "^Transcript\$" }
        },
        { title => "Sequence",
          url => "/{species}/LRG/Sequences?lrg={id}",
          conditions => { "{feature_type}" => "^Sequence\$",
                          "{id}" => "^LRG_" },
        },
        { title => "Reference Comparison",
          url => "/{species}/LRG/Differences?lrg={id}",
          conditions => { "{feature_type}" => "^Sequence\$",
                          "{id}" => "^LRG_" },
        },
      ],
    },
  };
}
1;


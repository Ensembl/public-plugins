// $Revision$

Ensembl.Panel.VEPResults = Ensembl.Panel.Content.extend({
  init: function () {
    var panel = this;
    
    this.base();
    
    this.el.find('a.zmenu').on('click', this.zmenu);
    
    this.el.find('a.filter_toggle').on('click', this.filter_toggle);
    
    this.el.find('input.autocomplete').on('focus', this.filter_autocomplete);
    //this.el.find('select.autocomplete').on('change', this.filter_autocomplete);
  },
  
  zmenu: function(e){
    var el = $(this);
    Ensembl.EventManager.trigger('makeZMenu', el.text().replace(/\W/g, '_'), { event: e, area: {a: el}});
    return false;
  },
  
  filter_toggle: function(e){
    $("." + this.rel).each(function() {
      this.style.display = (this.style.display == 'none' ? '' : 'none');
    });
  },
  
  filter_autocomplete: function(e){
      var el = $(this);
      var fieldNum = this.name.replace("field", "").replace("value", "");
      
      // find value and field input
      var value = $("input[name='value" + fieldNum + "']");
      var field = $("select[name='field" + fieldNum + "']");
      
      var autoValues = {
        Allele: [
          'A', 'C', 'G', 'T'
        ],
        Consequence: [
          'intergenic_variant',
          'intron_variant',
          'upstream_gene_variant',
          'downstream_gene_variant',
          '5_prime_utr_variant',
          '3_prime_utr_variant',
          'splice_region_variant',
          'splice_donor_variant',
          'splice_acceptor_variant',
          'frameshift_variant',
          'transcript_ablation',
          'transcript_amplification',
          'inframe_insertion',
          'inframe_deletion',
          'synonymous_variant',
          'stop_retained_variant',
          'missense_variant',
          'initiator_codon_variant',
          'stop_gained',
          'stop_lost',
          'mature_mirna_variant',
          'non_coding_exon_variant',
          'nc_transcript_variant',
          'incomplete_terminal_codon_variant',
          'nmd_transcript_variant',
          'coding_sequence_variant',
          'tfbs_ablation',
          'tfbs_amplification',
          'tf_binding_site_variant',
          'regulatory_region_variant',
          'regulatory_region_ablation',
          'regulatory_region_amplification'
        ],
        Feature_type: [
          'Transcript',
          'RegulatoryFeature',
          'MotifFeature'
        ],
        BIOTYPE: [
          'misc_RNA',
          'miRNA',
          'snRNA',
          'snoRNA',
          'rRNA',
          'protein_coding',
          'nonsense_mediated_decay',
          'retained_intron',
          'antisense',
          'pseudogene',
          'lincRNA',
          'processed_pseudogene',
          'processed_transcript',
          'sense_intronic',
          'unprocessed_pseudogene',
          'transcribed_processed_pseudogene',
          'transcribed_unprocessed_pseudogene',
          'unitary_pseudogene',
          'Mt_tRNA',
          'Mt_rRNA',
          'sense_overlapping',
          'IG_V_pseudogene',
          'TEC',
          '3prime_overlapping_ncrna',
          'non_stop_decay',
          'IG_C_pseudogene',
          'polymorphic_pseudogene',
          'IG_V_gene',
          'IG_D_gene',
          'IG_C_gene',
          'IG_J_gene',
          'TR_J_pseudogene',
          'TR_V_pseudogene',
          'TR_V_gene',
          'IG_J_pseudogene',
          'TR_J_gene',
          'TR_C_gene',
          'TR_D_gene',
          'LRG_gene'
        ],
        SIFT: [
          'tolerated',
          'deleterious'
        ],
        PolyPhen: [
          'benign',
          'possibly_damaging',
          'probably_damaging',
          'unknown'
        ]
      };
      
      if(autoValues[field[0].value] && autoValues[field[0].value].length) {
        value.autocomplete({
          minLength: 0,
          source: autoValues[field[0].value]
        });
      }
      else {
        value.autocomplete({});
      }
      
      // update placeholder
      if(field[0].value == 'Location') {
        value.attr("placeholder", "chr:start-end");
      }
      else {
        value.attr("placeholder", "defined");
      }
      
      return false;
  }
});

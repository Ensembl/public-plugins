// $Revision$

Ensembl.Panel.VEPResultsSummary = Ensembl.Panel.Piechart.extend({
  init: function () {
    // Consequence colours
    this.graphColours = {
      'intergenic_variant'                : 'gray',
      'intron_variant'                    : '#02599c',
      'upstream_gene_variant'             : '#8291A4',
      'downstream_gene_variant'           : '#a2b5cd',
      '5_prime_utr_variant'               : '#629EA4',
      '3_prime_utr_variant'               : '#7ac5cd',
      'splice_region_variant'             : '#ff7f50',
      'splice_donor_variant'              : '#CC6640',
      'splice_acceptor_variant'           : '#FF9973',
      'frameshift_variant'                : '#ff69b4',
      'transcript_ablation'               : '#ff0000',
      'transcript_amplification'          : '#ff69b4',
      'inframe_insertion'                 : '#ff69b4',
      'inframe_deletion'                  : '#ff69b4',
      'synonymous_variant'                : '#76ee00',
      'stop_retained_variant'             : '#76ee00',
      'missense_variant'                  : '#ffd700',
      'initiator_codon_variant'           : '#CCAC00',
      'stop_gained'                       : '#990000',
      'stop_lost'                         : '#ff0000',
      'mature_mirna_variant'              : '#458b00',
      'non_coding_exon_variant'           : '#32cd32',
      'nc_transcript_variant'             : '#84E184',
      'incomplete_terminal_codon_variant' : '#ff00ff',
      'nmd_transcript_variant'            : '#ff4500',
      'coding_sequence_variant'           : '#458b00',
      'tfbs_ablation'                     : 'brown',
      'tfbs_amplification'                : 'brown',
      'tf_binding_site_variant'           : 'brown',
      'regulatory_region_variant'         : 'brown',
      'regulatory_region_ablation'        : 'brown',
      'regulatory_region_amplification'   : 'brown',
      'default' : [ '#222222', '#FF00FF', '#008080', '#7B68EE' ]
    };
    
    this.base();
  },
  
  toggleContent: function (el) {
    if (el.hasClass('open') && !el.data('done')) {
      this.base(el);
      this.makeGraphs($('.pie_chart > div', '.' + el.attr('rel')).map(function () { return this.id.replace('graphHolder', ''); }).toArray());
      el.data('done', true);
    } else {
      this.base(el);
    }
    
    el = null;
  }
});

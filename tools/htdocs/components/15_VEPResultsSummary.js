// $Revision$

Ensembl.Panel.VEPResultsSummary = Ensembl.Panel.Piechart.extend({
  init: function () {
    this.base();
    
    // Consequence colours
    this.graphColours = JSON.parse(this.params['cons_colours'].replace(/\'/g, '"'));
    this.graphColours['default'] = [ '#222222', '#FF00FF', '#008080', '#7B68EE' ];
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

/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.TranscriptHaplotypes_new = Ensembl.Panel.Content.extend({
  init: function () {
    var panel = this;

    this.base();

    // get data
    this.haplotypeData = JSON.parse(this.params['haplotype_data']);
    delete this.params['haplotype_data'];
    this.populationStructure = JSON.parse(this.params['population_structure']);
    delete this.params['population_structure'];
    this.populationDescriptions = JSON.parse(this.params['population_descriptions']);
    delete this.params['population_descriptions'];

    // initialise details links
    this.el.find('a.details-link').on('click', function(e) {
      var div = $('div.details-view');

      div.show().empty().append(panel.detailsContent(this.rel));

      div.find('._ht').helptip();

      div.find('.toggle').on('click', function(e) {
        e.preventDefault();
        panel.el.find('#' + this.rel).toggle();

        var link = $(this);

        if(link.hasClass('closed')) {
          link.removeClass('closed').addClass('open');
        }
        else {
          link.removeClass('open').addClass('closed'); 
        }
      });

      div.find('a.zmenu').on('click', function(e) {
        e.preventDefault();
        Ensembl.EventManager.trigger('makeZMenu', $(this).text().replace(/\W/g, '_'), { event: e, area: { link: $(this) }});
      });
    });
  },

  fetchHaplotypeByHex: function(hex) {
    var panel = this;

    for(var i=0; i<panel.haplotypeData.protein_haplotypes.length; i++) {
      var haplotype = panel.haplotypeData.protein_haplotypes[i];
      if(haplotype.hex === hex) {
        return haplotype;
      }
    }

    for(var i=0; i<panel.haplotypeData.cds_haplotypes.length; i++) {
      var haplotype = panel.haplotypeData.cds_haplotypes[i];
      if(haplotype.hex === hex) {
        return haplotype;
      }
    }
  },

  detailsContent: function(hex) {
    var panel = this;

    // look up haplotype in JSON data
    var haplotype = panel.fetchHaplotypeByHex(hex);

    // failsafe
    if(typeof(haplotype) === 'undef') {
      return 'Unable to display details';
    }

    var html =
      '<hr/>' +
      '<span class="small" style="float:right;"><a href=#Haplotypes_new>Back to table</a></span>' +
      '<h2>Details of haplotype ' + haplotype.name.replace(/\,/g, ',&#8203;') + '</h2><div>';

    var sections = [
      { 'id': 'cds', 'title': 'Observed CDS haplotypes', 'sub': 'cdsHaplotypes'   },
      { 'id': 'seq', 'title': 'Aligned sequence',        'sub': 'alignedSequence' },
      { 'id': 'raw', 'title': 'Raw sequence',            'sub': 'rawSequence'     },
      { 'id': 'pop', 'title': 'Population frequencies',  'sub': 'populationTable' },
      { 'id': 'sam', 'title': 'Sample data',             'sub': 'sampleTable'     }
    ];

    var navs = [];
    var section_html = '';    

    for(var i in sections) {
      var section = sections[i];

      // navigation
      navs.push('<a href="#' + section.id + '">' + section.title + '</a>');

      // section content
      section_html = section_html +
        '<hr style="border-top-color: lightgrey"/>' + 
        '<div id="' + section.id + '">' +
        '<span class="small" style="float:right;"><i>Back to: </i><a href=#details-view>Haplotype</a> | <a href="#Haplotypes_new">Table</a></span>' +
        '<h3>' + section.title + '</h3>' +
        panel[section.sub](haplotype);
    }

    html = html + '<div><i>Jump to: </i>' + navs.join(' | ') + '</div>' + section_html + '</div>';

    return html;
  },

  cdsHaplotypes: function(haplotype) {
    var panel = this;

    var cdss = panel.getOtherHaplotypes(haplotype);

    var rows = [];

    for(var i in cdss) {
      var cds = cdss[i];

      var row = '<span id="' + cds.hex + '"><b>' + cds.name.replace(/\,/g, ',&#8203;') + '</b> (' + cds.count + ')</span>';

      row = row +
        '<br/><a href="#" class="toggle closed" rel="seq-' + cds.hex + '">Raw sequence</a>' +
        ' | <a href="#" class="toggle closed" rel="pop-' + cds.hex + '">Population frequencies</a>' +
        ' | <a href="#" class="toggle closed" rel="sam-' + cds.hex + '">Sample data</a>';

      row = row + '<div class="hidden" style="margin-top: 1em; display: none" id="seq-' + cds.hex + '">' + panel.rawSequence(cds) + '</div>';
      row = row + '<div class="hidden" style="margin-top: 1em; display: none" id="pop-' + cds.hex + '">' + panel.populationTable(cds) + '</div>';
      row = row + '<div class="hidden" style="margin-top: 1em; display: none" id="sam-' + cds.hex + '">' + panel.sampleTable(cds) + '</div>';

      rows.push(row);
    }

    var html =
      '<p><i>NB: More than one CDS sequence may encode the same protein sequence</i></p>' +
      '<ol>' + rows.map(function(a) {return '<li>' + a + '</li>'}).join("") + '</ol>';

    return html;
  },

  populationTable: function(haplotype) {
    var panel = this;

    var popStruct = panel.populationStructure;
    var descs = panel.populationDescriptions;

    var maxWidth = 120;

    var html = '<table class="ss" style="width:500px"><tr><th>Population group</th><th>Population</th><th style="width:' + (maxWidth + 100) + 'px">Frequency (count)</th></tr>';

    var superPops = Object.keys(popStruct).sort();

    for(var i in superPops) {
      var superPop = superPops[i];

      var first = 1;

      var rows = [];

      for(var j in popStruct[superPop]) {
        var subPop = popStruct[superPop][j];

        var row = '';

        var count = haplotype.population_counts.hasOwnProperty(subPop)      ? haplotype.population_counts[subPop]      : 0;
        var freq  = haplotype.population_frequencies.hasOwnProperty(subPop) ? haplotype.population_frequencies[subPop] : 0;

        if(!count) continue;

        if(first) {
          first = 0;
        }
        else {
          row = row + '<tr>';
        }

        row = row + '<td><span class="ht _ht" title="' + descs[subPop] + '">' + panel.shortName(subPop) + '</span></td><td>';

        // render frequency as a block
        row = row + '<nobr><div style="width:' + (maxWidth + 100) + 'px; float: left;">';
        row = row + '<div style="width:' + Math.round(freq * maxWidth) + 'px; background-color: #8b9bc1; float: left; display: inline; height: 1em;"></div>';
        row = row + '<div style="width:' + Math.round((1 - freq) * maxWidth) + 'px; background-color:lightgrey; float: left; display: inline; height: 1em;"></div>';
        row = row + '&nbsp;' + freq.toPrecision(3) + ' (' + count + ')</div></nobr>';

        row = row + '</td></tr>';

        rows.push(row);
      }

      html = html + '<tr><td rowspan="' + (rows.length > 0 ? rows.length : 1) + '"><b><span class="ht _ht" title="' + descs[superPop] + '">' + panel.shortName(superPop) + '</span></b></td>';

      if(rows.length) {
        html = html + rows.join("");
      }
      else {
        html = html + '<td colspan="2"><span style="font-style: italic; color: grey;">No data</span></td></tr>';
      }
    }

    html = html + '</table>';

    return html;
  },

  sampleTable: function(haplotype) {
    var panel = this;

    var html = '<table id="ind-table" class="ss" style="width:500px"><tr><th>Sample name</th><th>Haplotype copies / zygosity</th></tr>';

    var samples = Object.keys(haplotype.samples).sort();

    for(var i in samples) {
      var sample = samples[i];
      var count = haplotype.samples[sample];
      html = html + '<tr><td>' + panel.shortName(sample) + '</td><td>' + count + '</td></tr>';
    }

    html = html + '</table>';

    return html;
  },

  alignedSequence: function(haplotype) {
    var panel = this;

    // function to repeat a string
    String.prototype.repeat = function(num) {
      return new Array( num + 1 ).join( this );
    };

    // get protein stuff
    var refProtein = haplotype.aligned_sequences[0];
    var altProtein = haplotype.aligned_sequences[1];
    var longest = (refProtein.length >= altProtein.length ? refProtein.length : altProtein.length);

    // get diffs as a hash keyed on pos
    var protDiffs = panel.parseDiffs(haplotype);

    // get CDS stufff
    var others = panel.getOtherHaplotypes(haplotype);
    var refCDS = others[0].aligned_sequences[0].replace(/-/g, '');
    var altCDSs = others.map(function(a) {
      return a.aligned_sequences[1].replace(/-/g, '');
    });

    var cdsDiffs = others.map(function(a) {
      return panel.parseDiffs(a);
    });

    // initialise vars
    var protPos = 0;
    var cdsPos = 0;
    var cdsPosAlt = 0;
    var charsAdded = 0;
    var protFillChar = ' ';
    var matchChar = '.';
    var missingChar = '-';
    var seqHtml = '';
    var cdsAlternator = 1;

    // work out padding
    var padName = others.length.toString().length;

    // initialise with refProt, altProt, refCDS
    var seqsInit = [
      '<span><b>Protein</b>  REF ' + ' '.repeat(padName) + '</span>',
      '<span style="border-bottom: 1px solid grey">         ALT ' + ' '.repeat(padName) + '</span>',
      '<b>CDS</b>      REF ' + ' '.repeat(padName)];

    // initialise seq strings for alt CDS's
    for (var i = 0; i < others.length; i++) {
      seqsInit.push(
        '         <a class="_ht" href="#' + others[i].hex +
        '" title="' + others[i].name.replace(/\,/g, ',&#8203;') + ' (' + others[i].count + ')' +
        '">ALT' + (i + 1).toString() + '</a> ' +
        ' '.repeat(padName - (i+1).toString().length) // pad
      );
    }

    // copy
    var seqs = seqsInit.slice();

    while(protPos < longest) {

      var refAA = refProtein.substr(protPos, 1) || missingChar;
      var altAA = altProtein.substr(protPos, 1) || missingChar;
      altAA = (refAA === altAA ? matchChar : altAA);

      seqs[0] = seqs[0] + protFillChar + refAA + protFillChar;

      var protHtml;
      if(protDiffs.hasOwnProperty(protPos)) {
        protHtml =
          '<span class="ht _ht" style="color:white; background-color:' + protDiffs[protPos].colour + '" ' +
          'title="' + protDiffs[protPos].html + '">' +
           protFillChar + altAA + protFillChar +
           '</span>';
      }
      else {
        protHtml = protFillChar + altAA + protFillChar;
      }
      seqs[1] = seqs[1] + protHtml;

      var refCodon;
      if(refAA === missingChar) {
        refCodon = missingChar.repeat(3);
        seqs[2] = seqs[2] + refCodon;
      }
      else {
        refCodon = refCDS.substr(cdsPos, 3);
        seqs[2] = seqs[2] + (cdsAlternator ? refCodon : '<span style="background-color:#fff9af">' + refCodon + '</span>');
        cdsAlternator = 1 - cdsAlternator;
      }

      for(var i in altCDSs) {
        var altCodon = (altAA === missingChar ? missingChar.repeat(3) : altCDSs[i].substr(cdsPosAlt, 3));
        var cdsHtml = '';

        for(var j=0; j<refCodon.length; j++) {
          var refBase = refCodon.substr(j, 1);
          var altBase = altCodon.substr(j, 1);
          var base = (refBase === altBase ? '.' : altBase);
          
          if(cdsDiffs[i].hasOwnProperty(cdsPos + j)) {
            if(cdsDiffs[i][cdsPos + j].hasOwnProperty('variation_feature')) {
              cdsHtml = cdsHtml +
                '<a class="sequence_info zmenu" draggable="false" href="/Homo_sapiens/ZMenu/Variation?v=' +
                cdsDiffs[i][cdsPos + j].variation_feature +
                '&vf=' + cdsDiffs[i][cdsPos + j].variation_feature_id + '">' +
                base + '</a>';
              // cdsHtml = cdsHtml +
              //   '<a class="sequence_info zmenu" draggable="false" href="/Homo_sapiens/ZMenu/TextSequence?' +
              //   'vf=' + cdsDiffs[i][cdsPos + j].variation_feature_id +
              //   '&t=' + others[i].name.replace(/\:.+/g, "") + '">' +
              //   base + '</a>';
            }
            else {
              cdsHtml = cdsHtml + '<span class="ht _ht" title="Unable to identify corresponding variant">' + base + '</span>';
            }
          }
          else {
            cdsHtml = cdsHtml + base;
          }
        }
        
        seqs[parseInt(i) + 3] = seqs[parseInt(i) + 3] + cdsHtml;
      }

      protPos++;
      cdsPos = cdsPos + (refAA === missingChar ? 0 : 3);
      cdsPosAlt = cdsPosAlt + (altAA === missingChar ? 0 : 3);
      charsAdded += 3;

      if(charsAdded >= 60) {
        seqHtml = seqHtml + seqs.join("\n") + "\n\n";
        var seqs = seqsInit.slice();
        charsAdded = 0;
      }
    }
    
    seqHtml = seqHtml + seqs.join("\n") + "\n\n";

    var html = panel.sequenceKey() + '<pre>' + seqHtml + '</pre>';

    return html;
  },

  sequenceKey: function() {
    var html =
      '<div class="adornment-key"><dl>' +

      '<dt>Sequence</dt><dd><ul>' +
      '<li><span style="border: 1px solid lightgrey">.&nbsp;&nbsp;Match</span></li>' +
      '<li><span style="border: 1px solid lightgrey">-&nbsp;&nbsp;Missing sequence</span></li>' +
      '</ul></dd>' +

      '<dt>Codons</dt><dd><ul>' +
      '<li><span>Alternating codons</span></li>' +
      '<li><span style="background-color: #fff9af">Alternating codons</span></li>' +
      '</ul></dd>' +

      '<dt>Protein changes</dt><dd><ul>' +
      '<li><span style="color: white; background-color:red">Deleterious/damaging</span></li>' +
      '<li><span style="color: white; background-color:green">Tolerated/benign</span></li>' +
      '<li><span style="color: white; background-color:#ff69b4">Insertion or deletion</span></li>' +
      '<li><span style="color: white; background-color:red">Stop gain or loss</span></li>' +
      '<li><span style="color: white; background-color:grey">Other</span></li>' +
      '</ul></dd>' +
      
      '</dl></div>';

    return html;
  },

  parseDiffs: function(haplotype) {
    var panel = this;

    var diffs = {};

    for(var i in haplotype.diffs) {
      var diff = haplotype.diffs[i];

      var raw_diff = diff.diff;

      // get start pos
      var pos = parseInt(raw_diff.match(/\d+/g)[0]);
      var end = pos;

      // get end pos
      // ins/del (number)
      if(raw_diff.match(/{(\d+)}/)) {
        end = (pos + parseInt(raw_diff.match(/{(\d+)}/)[1])) - 1;
      }

      // bases
      else if(raw_diff.match(/[A-Z\*]+$/)) {
        end = (pos + raw_diff.match(/[A-Z\*]+$/)[0].length) - 1;
      }

      // create HTML for mouseover
      var html = '<p><b>' + raw_diff + '</b></p>';
      
      var colour = 'grey';

      if(raw_diff.match(/ins|del/)) {
        colour = '#ff69b4';
      }
      else if(raw_diff.match(/\*/)) {
        colour = 'orange';
      }

      var preds = ['PolyPhen', 'SIFT'];

      for(var i in preds) {
        var pred = preds[i];
        var lcPred = pred.toLowerCase();

        var prediction = undefined;
        var score = undefined;

        if(diff.hasOwnProperty(lcPred + '_prediction')) {
          prediction = diff[lcPred + '_prediction'];
        }
        if(diff.hasOwnProperty(lcPred + '_score')) {
          score = diff[lcPred + '_score'];
        }

        if(!(typeof(prediction) === 'undefined')) {
          if(prediction.match(/deleterious$/) || prediction.match(/probably.damaging/)) {
            colour = 'red';
          }
          else if(colour === 'grey' && (prediction.match(/tolerated$/) || prediction.match(/benign/))) {
            colour = 'green';
          }

          html = html + '<b>' + pred + '</b>: ' + prediction + ' (' + score + ')<br/>';
        }
      }

      diff.colour = colour;
      diff.html = html;

      for(var i = pos - 1; i < end; i++) {
        diffs[i] = diff;
      };
    }

    return diffs;
  },

  rawSequence: function(haplotype) {
    return this.fastaSequence(haplotype.name, haplotype.seq);
  },

  fastaSequence: function(id, seq, lineLength) {
    if(typeof(lineLength) === 'undefined') lineLength = 60;

    var re = new RegExp("(.{1," + lineLength + "})", "g");
    return '<pre>&gt;' + id + "\n" + seq.match(re).join("\n") + '</pre>';
  },

  getOtherHaplotypes: function(haplotype) {
    var panel = this;
    var others = [];

    for(var hex in haplotype.other_hexes) {
      others.push(panel.fetchHaplotypeByHex(hex));
    }

    // sort by haplotype count, highest first
    others = others.sort(function (a, b) {
      if (a.count < b.count) {
        return 1;
      }
      if (a.count > b.count) {
        return -1;
      }
      return 0;
    });

    return others;
  },

  shortName: function(name) {
    return name.replace('1000GENOMES:phase_3:','');
  }
});

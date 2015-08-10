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

window.onload = function() {
  loadCascaded(['/highcharts/highcharts.js', '/highcharts/exporting.js', function() { ToolsGraphs.init(); }]);
}

function loadCascaded(codes) {
  var src   = codes.shift();
  var data  = codes[0] && typeof codes[0] === 'object' ? codes.shift() : {};
  var isJS  = !!src.match(/.js$/);

  $.ajax({
    url       : src,
    cache     : isJS,
    data      : data,
    dataType  : isJS ? 'script' : 'json',
    success   : codes.length ? typeof codes[0] === 'string' ? function() {
      loadCascaded(codes);
    } : codes[0] : function() {}
  });
}

ToolsGraphs = {

  dateFormat  : 'dd/mm/yy',
  types       : [],
  loadedGraph : {},
  graphDivs   : {},

  init: function() {

    this.contents = $('._content');

    // types of graph
    this.types = this.contents.map(function () {
      return this.className.match(/_content_([a-z]+)/).pop();
    }).toArray();

    // grpah container for each graph
    $.each(this.types, function (i, type) {
      ToolsGraphs.graphDivs[type] = {};
      ToolsGraphs.contents.filter('._content_' + type).find('div').filter(function() { return !!this.className.match(/_graph_/); }).each(function() {
        ToolsGraphs.graphDivs[type][this.className.match('_graph_([^ ]+)').pop()] = $(this);
      });
    });

    $('._tab').tabs(this.contents, 'click').on('click', function () {
      ToolsGraphs.loadGraph();
    });

    this.contents.find('form._form').find('._datepicker').each(function () {
      this.value  = $.datepicker.formatDate(ToolsGraphs.dateFormat, this.name === 'to' ? new Date(new Date().setDate(new Date().getDate() + 1)) : new Date())
    })
    .datepicker({ dateFormat: this.dateFormat }).end().on('submit', function (e) {
      e.preventDefault();

      var type = $(this).closest('._content').attr('class').match(/_content_([a-z]+)/).pop();

      $.each(ToolsGraphs.graphDivs[type], function() {
        this.addClass('loading');
      })

      ToolsGraphs.loadedGraph[type] = false;
      ToolsGraphs.loadGraph(type);
    }).trigger('submit');
  },

  loadGraph: function(type) {

    $.each(type && [ type ] || this.types, function (i, type) {

      if (ToolsGraphs.loadedGraph[type]) {
        return true;
      }

      if (!ToolsGraphs.contents.filter('._content_' + type).is(':visible')) {
        return true;
      }

      ToolsGraphs.loadedGraph[type] = true;

      var data = {};

      ToolsGraphs.contents.filter('._content_' + type).find('._datepicker').each(function () {
        data[this.name] = $.datepicker.formatDate('@', $.datepicker.parseDate(ToolsGraphs.dateFormat, this.value)) / 1000;
      });

      $.each(ToolsGraphs.graphDivs[type], function (toolType, el) {
        loadCascaded(['/Ajax/' + type + 'time_tools_stats?type=' + toolType, data, function(t1, t2) { return function() {
          ToolsGraphs.graphDivs[t1][t2].removeClass('loading');
          t1 === 'processing'
            ? ToolsGraphs.displayProcessingTimeGraph($.extend({type: t2}, arguments[0]))
            : ToolsGraphs.displayWaitTimeGraph($.extend({type: t2}, arguments[0]))
          ;
        }}(type, toolType)]);
      })
      return true;
    });
  }
}

ToolsGraphs.displayWaitTimeGraph = function(json) {

  var container = ToolsGraphs.graphDivs['wait'][json.type].prev('._subhead').remove().end();

  if (json.error) {
    container.html('<div class="error"><h3>Data error</h3><div class="message-pad"><p>' + json.error + '</p></div></div>');
    return;
  }

  var data = [];

  for (var i = 0; i < 24 * 3600; i++) {
//    if (json.data[i]) {
      data.push([(json.offset + i) * 1000, json.data[i] || 0]);
//    }
  }

  container.before('<h2 class="_subhead top-margin">From ' + unixTimeToString(json.offset) + ' to ' + unixTimeToString(json.offset + 24 * 3600) + '</h2>').highcharts({
    chart: {
      zoomType: 'x'
    },
    title: {
      text: null,
    },
    subtitle: {
      text: 'Number of jobs waiting in the queue',
    },
    xAxis: {
      allowDecimals: false,
      type: 'datetime',
      minRange: 3600000 // one hour
    },
    yAxis: {
      title: {
        text: 'Number of jobs'
      }
    },
    legend: {
      enabled: false
    },
    plotOptions: {
      area: {
        fillColor: {
          linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1},
          stops: [
            [0, Highcharts.getOptions().colors[0]],
            [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
          ]
        },
        marker: {
          radius: 2
        },
        lineWidth: 1,
        threshold: null
      }
    },

    series: [{
      type: 'area',
      name: 'Waiting time for jobs',
      pointInterval: 1000, // one second
      pointStart: json.offset * 1000, // 24 hours
      data: data
    }]
  });

  data = json = null;
}

ToolsGraphs.displayProcessingTimeGraph = function (json) {

  var container = ToolsGraphs.graphDivs['processing'][json.type].prev('._subhead').remove().end();

  if (json.error) {
    container.html('<div class="error"><h3>Data error</h3><div class="message-pad"><p>' + json.error + '</p></div></div>');
    return;
  }

  var data  = [];
  var x     = 0;
  var entry;
  while (json.data.length) {
    entry = json.data.shift();
    if (typeof entry !== 'number') {
      while (entry[1]--) {
        data.push([x++, entry[0]]);
      }
    } else {
      data.push([x++, entry]);
    }
  }

  container.before('<h2 class="_subhead top-margin">From ' + unixTimeToString(json.from) + ' to ' + unixTimeToString(json.to) + '</h2>').highcharts({
    chart: {
      zoomType: 'x',
      type: 'column'
    },
    title: {
      text: null,
    },
    subtitle: {
      text: 'Processing time for ' + json.type.toUpperCase() + ' jobs (' + (json.setsize === 1 ? '1 job' : 'Set of ' + json.setsize + ' jobs') + ' at a point)',
    },
    xAxis: {
      allowDecimals: false,
    },
    yAxis: {
      title: {
        text: 'Time taken (seconds)'
      },
      formatter: function() {
        return this.value / 1000;
      }
    },
    legend: {
      enabled: false
    },

    series: [{
      type: 'column',
      animation: false,
      pointInterval: 1,
      pointStart: 1,
      data: data,
      tooltip: {
        pointFormatter: function () {
          return 'Processing time: ' + (this.y < 3600 ? this.y < 60 ? this.y + ' seconds' : Math.round(this.y/60) + ' minutes' : Math.round(this.y/3600) + ' hours');
        }
      }
    }]
  });

  data = json = null;
}

function unixTimeToString(unixTime) {
  var t = new Date(unixTime * 1000);
  var m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  var z = function (i) { return i < 10 ? '0' + i : i; }

  return m[t.getMonth()] + ' ' + z(t.getDate()) + ', ' + t.getFullYear() + ' ' + z(t.getHours()) + ':' + z(t.getMinutes());
}


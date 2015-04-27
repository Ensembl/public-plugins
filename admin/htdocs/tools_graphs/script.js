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
  loadCascaded(['/highcharts/highcharts.js', '/highcharts/exporting.js', function() { initGraphs(); }]);
}

function loadCascaded(codes) {
  var src   = codes.shift();
  var isJS  = !!src.match(/.js$/);
  var data  = isJS ? {} : (window.location.search || '').replace('?', '');

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

function initGraphs() {
  var types = ['Blast', 'Blat', 'VEP'];
  for (var i in types) {
    loadCascaded(['/Ajax/tools_stats?type=' + types[i], function(t) { return function() { displayGraph($.extend({type: t}, arguments[0])); } }(types[i])]);
  }
}

function displayGraph(json) {

  var container = $('._tools_graph_' + json.type);

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

  container.before('<h2 class="top-margin">From ' + unixTimeToString(json.offset) + ' to ' + unixTimeToString(json.offset + 24 * 3600) + '</h2>').highcharts({
    chart: {
      zoomType: 'x'
    },
    title: {
      text: json.type.toUpperCase() + ' jobs',
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
        states: {
          hover: {
            lineWidth: 1
          }
        },
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

function unixTimeToString(unixTime) {
  var t = new Date(unixTime*1000);
  var m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return m[t.getMonth()] + ' ' + t.getDate() + ', ' + t.getFullYear() + ' ' + t.getHours() + ':' + t.getMinutes();
}


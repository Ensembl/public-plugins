/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2021] EMBL-European Bioinformatics Institute
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

Genoverse.Track.View.Gene = Genoverse.Track.View.extend({
  featureHeight : 6,
  featureMargin : { top: 0, right: 1, bottom: 1, left: 0 },
  bump          : true,
  labels        : 'separate'
});

Genoverse.Track.View.Gene.Collapsed = Genoverse.Track.View.Gene.extend({
  featureHeight : 8,
  featureMargin : { top: 3, right: 1, bottom: 1, left: 0 },
  labels        : true,
  
  drawFeature: function (feature, featureContext, labelContext, scale) {
    var add      = Math.max(scale, 1);
    var exons    = {};
    var exonsIds = [];
    
    for (var i = 0; i < feature.exons.length; i++) {
      this.base($.extend({}, feature, {
        x         : feature.x + (feature.exons[i].start - feature.start) * scale, 
        width     : (feature.exons[i].end - feature.exons[i].start) * scale + add,
        label     : false,
        highlight : i ? false : feature.highlight
      }, feature.exons[i].style === 'strokeRect' ? {
        y           : feature.y + 1,
        height      : feature.height - 3,
        color       : false,
        borderColor : feature.color
      } : {}), featureContext, labelContext, scale);
      
      if (this.expanded) {
        // For partially coding exons, the exon is duplicated in the array, with one strokeRect and one fillRect
        // In this case we want to ensure that the intron line is drawn from the real start and end - the maximum of these values between the duplicated exons
        if (!exons[feature.exons[i].id]) {
          exons[feature.exons[i].id] = { start: 9e99, end: -9e99 };
          exonsIds.push(feature.exons[i].id);
        }
        
        exons[feature.exons[i].id].start = Math.min(exons[feature.exons[i].id].start, feature.exons[i].start);
        exons[feature.exons[i].id].end   = Math.max(exons[feature.exons[i].id].end,   feature.exons[i].end);
      }
    }
    
    if (this.expanded) {
      for (i = 1; i < exonsIds.length; i++) {
        this.drawIntron({
          start : feature.x + (exons[exonsIds[i - 1]].end - feature.start) * scale + add,
          end   : feature.x + (exons[exonsIds[i]].start   - feature.start) * scale,
          y     : feature.y + this.featureHeight / 2,
          y2    : feature.y + (feature.strand > 0 ? 0 : this.featureHeight),
          color : feature.color
        }, featureContext);
      }
    } else if (feature.exons.length > 1) {
      featureContext.fillRect(feature.position[scale].X, feature.position[scale].Y + this.featureHeight / 2, feature.position[scale].width, 1);
    }
    
    if (this.labels && feature.label) {
      this.drawLabel(feature, labelContext, scale);
    }
  },
  
  drawIntron: function (feature, context) {
    var x1 = feature.start; // x coord of the right edge of the first exon
    var x3 = feature.end;   // x coord of the left edge of the second exon
    
    // Skip if completely outside the image's region
    if (x3 < 0 || x1 > this.width) {
      return;
    }
    
    var xMid   = (x1 + x3) / 2;
    var x2     = xMid;                    // x coord of the peak of the hat
    var y1     = feature.y;               // y coord of the ends of the line (half way down the exon box)
    var y3     = y1;
    var y2     = feature.y2;              // y coord of the peak of the hat  (level with the top (forward strand) or bottom (reverse strand) of the exon box)
    var yScale = (y2 - y1) / (xMid - x1); // Scale factor for recalculating coords if points lie outside the image region
    
    if (xMid < 0) {
      y2 = feature.y + (yScale * x3);
      x2 = 0;
    } else if (xMid > this.width) {
      y2 = feature.y + (yScale * (this.width - feature.start));
      x2 = this.width;
    }
    
    if (x1 < 0) {
      y1 = xMid < 0 ? y2 : feature.y - (yScale * feature.start);
      x1 = 0;
    }
    
    if (x3 > this.width) {
      y3 = xMid > this.width ? y2 : y2 - (yScale * (this.width - x2));
      x3 = this.width;
    }
    
    context.strokeStyle = feature.color;
    
    context.beginPath();
    context.moveTo(x1, y1);
    context.lineTo(x2, y2);
    context.lineTo(x3, y3);
    context.stroke();
  }
});

Genoverse.Track.View.Gene.Transcript = Genoverse.Track.View.Gene.Collapsed.extend({
  featureMargin : { top: 3, right: 1, bottom: 3, left: 0 },
  expanded      : true,

  positionFeature: function (feature, params) {
    var scale = params.scale;

    feature.position[scale].X = feature.position[scale].start - params.scaledStart; // FIXME: always have to reposition for X, in case a feature appears in 2 images. Pass scaledStart around instead?

    if (!feature.position[scale].positioned) {
      feature.position[scale].H = feature.position[scale].height + this.featureMargin.bottom;
      feature.position[scale].W = feature.position[scale].width + (feature.marginRight || this.featureMargin.right);
      feature.position[scale].Y = (typeof feature.y === 'number' ? feature.y * feature.position[scale].H : 0) + this.featureMargin.top;

      if (feature.label) {
        if (typeof feature.label === 'string') {
          feature.label = feature.label.split('\n');
        }

        var context = this.context;

        feature.labelHeight = feature.labelHeight || (this.fontHeight + 2) * feature.label.length;
        feature.labelWidth  = feature.labelWidth  || Math.max.apply(Math, $.map(feature.label, function (l) { return Math.ceil(context.measureText(l).width); })) + 1;

        if (this.labels === true) {
          feature.position[scale].H += feature.labelHeight;
          feature.position[scale].W  = Math.max(feature.labelWidth, feature.position[scale].W);
        } else if (this.labels === 'separate' && !feature.position[scale].label) {
          feature.position[scale].label = {
            x: feature.position[scale].start,
            y: feature.position[scale].Y,
            w: feature.labelWidth,
            h: feature.labelHeight
          };
        }
      }

      var bounds = {
        x: feature.position[scale].start,
        y: feature.position[scale].Y,
        w: feature.position[scale].W,
        h: feature.position[scale].H + this.featureMargin.top + 7 
      };

      if (this.bump === true) {
        this.bumpFeature(bounds, feature, scale, this.scaleSettings[scale].featurePositions);
      }

      this.scaleSettings[scale].featurePositions.insert(bounds, feature);

      feature.position[scale].bottom = feature.position[scale].Y + feature.position[scale].H + params.margin;

      if (feature.position[scale].label) {
        var f = $.extend(true, {}, feature); // FIXME: hack to avoid changing feature.position[scale].Y in bumpFeature

        this.bumpFeature(feature.position[scale].label, f, scale, this.scaleSettings[scale].labelPositions);

        f.position[scale].label        = feature.position[scale].label;
        f.position[scale].label.bottom = f.position[scale].label.y + f.position[scale].label.h + params.margin;

        feature = f;

        this.scaleSettings[scale].labelPositions.insert(feature.position[scale].label, feature);

        params.labelHeight = Math.max(params.labelHeight, feature.position[scale].label.bottom);
      }

      feature.position[scale].positioned = true;
    }

    params.featureHeight = Math.max(params.featureHeight, feature.position[scale].bottom);
    params.height        = Math.max(params.height, params.featureHeight + params.labelHeight);
  },
});
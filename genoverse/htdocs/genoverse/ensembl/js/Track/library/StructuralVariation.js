/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
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

Genoverse.Track.StructuralVariation = Genoverse.Track.extend({
  height: 100,
  
  view: Genoverse.Track.View.extend({
    labels        : false,
    featureMargin : { top: 0, right: 1, bottom: 1, left: 0 },
    
    init: function () {
      if (this.prop('renderer') === 'compact') {
        this.depth         = 1;
        this.bump          = false;
        this.featureHeight = 12;
      } else {
        this.bump          = true;
        this.featureHeight = 6;
      }
      
      this.decorationHeight = this.featureHeight - 1;
      this.base();
    },
    
    positionFeature: function (feature, params) {
      var scale = params.scale;
      var width = feature.position[scale].width;
    
      if (!feature.adjusted) {
        for (var i = 0; i < feature.decorations.length; i++) {
          if (feature.decorations[i].style.match(/^bound_triangle_(\w+)$/)) {
            feature.position[scale].width += this.decorationHeight / 2;
          }
        }
        
        feature.adjusted = true;
      }
      
      this.base(feature, params);
      
      feature.position[scale].width = width;
    },
    
    bumpFeature: function (bounds, feature, scale, tree) {
      var breakpoints = this.prop('breakpoints');
      var i;
      
      if (feature.breakpoint) {
        if (bounds.y === 0 || feature.length > this.browser.length) {
          this.base(bounds, feature, scale, tree);
          
          for (i = 0; i < breakpoints[feature.featureId].length; i++) {
            breakpoints[feature.featureId][i].y = bounds.y / (bounds.h + this.bumpSpacing);
          }
        }
        
        return;
      }
      
      for (i = 0; i < feature.decorations.length; i++) {
        switch (feature.decorations[i].style) {
          case 'bound_triangle_left'  : bounds.x -= this.decorationHeight / 2; break;
          case 'bound_triangle_right' : bounds.w += this.decorationHeight / 2; break;
          default                     : break;
        }
      }
      
      this.base(bounds, feature, scale, tree);
    },
    
    drawFeature: function (feature, featureContext, labelContext, scale) {
      if (!feature.breakpoint) {
        return this.base(feature, featureContext, labelContext, scale);
      }
      
      featureContext.fillStyle   = feature.color;
      featureContext.strokeStyle = feature.border;
      
      var position    = feature.position[scale];
      var breakpointH = this.decorationHeight * 2;
      var x           = position.X;
      var y           = position.Y + 0.5;
      
      featureContext.beginPath();
      featureContext.moveTo(x - 0.5, y);
      featureContext.lineTo(x + 4.5, y);
      featureContext.lineTo(x + 2.5, y + breakpointH / 3);
      featureContext.lineTo(x + 5.5, y + breakpointH / 3);
      featureContext.lineTo(x,       y + breakpointH);
      featureContext.lineTo(x + 0.5, y + breakpointH * 2 / 3 - 1);
      featureContext.lineTo(x - 3.5, y + breakpointH * 2 / 3 - 1);
      featureContext.closePath();
      featureContext.fill();
      featureContext.stroke();
    },
    
    decorateFeature: function (feature, context, scale) {
      var i           = feature.decorations.length;
      var h           = this.decorationHeight;
      var mid         = h / 2;
      var position    = feature.position[scale];
      var startOffset = position.start - position.X;
      var margin      = feature.marginRight || this.featureMargin.right;
      var decoration, x, x2, y, triangle, dir;
      
      while (i--) {
        decoration = feature.decorations[i];
        triangle   = decoration.style.match(/^bound_triangle_(\w+)$/);
        
        context.fillStyle   = decoration.color;
        context.strokeStyle = decoration.border;
        
        if (triangle) {
          dir = !!decoration.out === (triangle[1] === 'left');
          x   = Math.floor((dir ? position.X + position.width + margin - Math.max(scale, 1) : position.X) + (dir ? 1 : -1) * (decoration.out ? mid : 0)) + 0.5;
          x2  = x + ((triangle[1] === 'left' ? -1 : 1) * mid);
          y   = position.Y + 0.5;
          
          if (Math.max(x, x2) > 0 && Math.min(x, x2) < this.width) {
            context.beginPath();
            context.moveTo(x, y);
            context.lineTo(x2, y + mid);
            context.lineTo(x, y + h);
            context.closePath();
            context.fill();
            context.stroke();
          }
        } else if (decoration.style === 'rect') {
          decoration.x     = decoration.start * scale - startOffset;
          decoration.width = (decoration.end - decoration.start) * scale + Math.max(scale, 1);
          
          if (decoration.x < 0 || decoration.x + decoration.width > this.width) {
            this.truncateForDrawing(decoration);
          }
          
          context.fillRect(decoration.x, position.Y, decoration.width, this.featureHeight);
        }
      }
    }
  }),
    
  model: Genoverse.Track.Model.extend({
    init: function () {
      this.decorationHeight = this.featureHeight - 1;
      this.breakpoints = {};
      this.base();
    },
    
    insertFeature: function (feature) {
      if (feature.breakpoint && !this.featuresById[feature.id]) {
        this.breakpoints[feature.featureId] = this.breakpoints[feature.featureId] || [];
        this.breakpoints[feature.featureId].push(feature);
        feature.breakpoint = this.breakpoints[feature.featureId].length;
      }
      
      this.base(feature);
    }
  }),
  
  controller: Genoverse.Track.Controller.extend({
    setScale: function () {
      this.base();
      this.prop('dataBuffer').start = this.prop('dataBuffer').end = Math.ceil(9 / this.browser.scale);
    }
  })
});
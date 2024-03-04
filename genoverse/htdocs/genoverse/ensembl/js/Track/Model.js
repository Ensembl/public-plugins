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

Genoverse.Track.Model = Genoverse.Track.Model.extend({
  getData: function (start, end, done) {
    var callback = function (data) {
      if (data) {
        if (data.dataRange) {
          this.setDataRange(data.dataRange.start, data.dataRange.end);
        }

        if (data.cacheURL) {
          $.ajax({ url: data.cacheURL });
        }
      }
    };

    return this.base(start, end, typeof done !== 'function' ? callback : function () {
      done.apply(this, arguments);
      callback.apply(this, arguments);
    });
  },

  parseData: function (data, start, end) {
    if (data.error) {
      this.track.controller.showError(data.error);
    } else {
      if (data.highlights) {
        var i = data.features.length;

        while (i--) {
          if (data.highlights[data.features[i].id]) {
            data.features[i].highlight = data.highlights[data.features[i].id];
          }
        }
      }

      return this.base(data.features, start, end);
    }
  },

  setURL: function () {
    $.extend(this.urlParams, Ensembl.coreParams);
    this.urlParams.r = '__CHR__:__START__-__END__';
    this.base.apply(this, arguments);
  }
});

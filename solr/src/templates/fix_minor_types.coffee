# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

sequence_type =
  'contig': 'Contig'
  'clone': 'Clone'
  'chromosome': 'Chromosome'
  'lrg': 'LRG'

window.fixes ?= {}
window.fixes.fix_minor_types =
  fixes:
    global: [
      (data) -> # Extract good info from description
        data.tp2_row.register 1000, () ->
          ft = data.tp2_row.best('feature_type')
          sp = data.tp2_row.best('species')
          if ft == 'Phenotype'
            data.tp2_row.candidate('id',sp+' Phenotype',1000)

        data.tp2_row.register 25000, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'Protein Domain'
            sp = data.tp2_row.best('species')
            data.tp2_row.candidate('bracketed',ft+' in '+sp,10000)

        data.tp2_row.register 26000, () ->
          strain = data.tp2_row.best('strain')
          if strain?
            sp = data.tp2_row.best('species')
            br = data.tp2_row.best('bracketed')
            strain = strain.replace(/_/g,' ')
            strain = strain.replace(new RegExp('^'+sp+' '),'')
            
            strain_type = $.solr_config('static.ui.strain_type.%', sp);
            if !strain_type
              strain_type = 'Strain';
            strain_type = strain_type.charAt(0).toUpperCase() + strain_type.substring(1)
            data.tp2_row.candidate('bracketed',br+', '+strain_type+': '+strain,15000)

        data.tp2_row.register 300, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'Family'
            inner_desc = undefined
            main_desc = data.tp2_row.best('description')
            main_desc = main_desc.replace /\[(.*?)\]/g, (g0,g1) ->
              inner_desc = $.trim(g1)
              ''
            main_desc = $.trim(main_desc.replace(/has$/,''))
            data.tp2_row.candidate('domfam_inner_desc',inner_desc,1000)
            data.tp2_row.candidate('domfam_rem_desc',main_desc,1000)
          if ft == 'Family'
            data.tp2_row.candidate('title_feature_type','Protein Family',300)
          if ft == 'Marker'
            id = data.tp2_row.best('id')
            data.tp2_row.add_value('new-contents',"Marker "+id,300)
            data.tp2_row.add_value('new-contents',data.tp2_row.best('description'),1000)
          if ft == 'Sequence'
            id = data.tp2_row.best('id')
            desc = data.tp2_row.best('description')
            if id.match(/^LRG_/)
              data.tp2_row.add_value('new-contents',"<i>LRG sequence (Locus Reference Genomic)</i>",1000)
              data.tp2_row.add_value('new-contents',data.tp2_row.best('description'),100)
            for k,v of sequence_type
              if desc.toLowerCase().substring(0,k.length) == k
                data.tp2_row.add_value('bracketed-title',v,295)
          if ft == 'GenomicAlignment'
            desc = data.tp2_row.best('description')
            if desc.match(/ESTs?/)
              data.tp2_row.candidate('title_feature_type','EST',300)
            else
              data.tp2_row.candidate('title_feature_type','Genomic Alignment',150)
          if ft == 'ProbeFeature'
            type = ['Probe']
            desc = data.tp2_row.best('description')
            m = desc.match /^([A-Z]+) probe/
            if m?[0]? then type.unshift(m[1])
            data.tp2_row.candidate('title_feature_type',type.join(' '),300)

        data.tp2_row.register 1000, () ->
          prefix_contents = undefined
          ft = data.tp2_row.best('feature_type')
          rem = data.tp2_row.best('domfam_rem_desc')
          inner = data.tp2_row.best('domfam_inner_desc')
          main = undefined
          if ft == 'Protein Domain'
            main = inner
            prefix_contents = [rem,inner]
          else if ft == 'Family'
            main = 'Protein Family ' + data.tp2_row.best('id')
            prefix_contents = [main,inner]
          if prefix_contents?
            # XXX use existing contents
            for p,idx in prefix_contents
              if p?.match /\w/
                data.tp2_row.add_value('new-contents',p,100*idx+100)
          if main? then data.tp2_row.candidate('main-title',main,300)

        true
    ]


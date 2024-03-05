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

title_reword =
  'cisRED motifs': 'cisRED'
  'cisRED search regions': 'cisRED'
  'VISTA enhancer set': 'VISTA'
  'miRanda miRNA targets': 'miRanda'

expand_for_desc =
  'VISTA': 'the VISTA enhancer set'
  'miRanda': 'the miRanda miRNA target predictions'

expand_for_title =
  'RNA': 'miRNA'
  'Search Region': 'Search region'

feature_type =
  'Regulatory Motif': 'Feature'

format =
  _default: "{reg_id} is [${reg_what_desc}$] from {reg_from_desc} {reg_tail}"
  miranda: "{reg_id} is a miRanda miRNA target prediction {reg_tail}"
  cisred: "{reg_id} is [{reg_from_desc}] <{reg_what_desc}> {reg_tail}"

_a = (word) ->
  a_an = ('aeiouAEIOU'.indexOf(word.charAt(0)) != -1 or
          $.inArray(word.toLowerCase(),['rna']) != -1)
  return ( if a_an then 'an ' else 'a ' ) + word

_lc = (word) ->
  w = word.toLowerCase()
  if $.inArray(w,['rna']) != -1
    word.toUpperCase()
  else
    w

window.fixes ?= {}
window.fixes.fix_regulation =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 150, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'RegulatoryFeature'
            desc = data.tp2_row.best('description')
            m = desc.match(/^(\S+) is a (.*?) from (.*?) (which hits .*)$/)
            if m?
              [reg_id,reg_what,reg_from,reg_tail] = m[1..4]
              for from,to of title_reword
                if reg_what == from then reg_what = to
                if reg_from == from then reg_from = to
              data.tp2_row.candidate('reg_id',  reg_id,50)
              data.tp2_row.candidate('reg_what',reg_what,50)
              data.tp2_row.candidate('reg_from',reg_from,50)
              data.tp2_row.candidate('reg_tail',reg_tail,50)
          true

        data.tp2_row.register 300, () ->
          reg_what = data.tp2_row.best('reg_what')
          reg_from = data.tp2_row.best('reg_from')
          for match,name of feature_type
            if reg_what == match or reg_from == match
              data.tp2_row.candidate('title_feature_type',name,100)
          if data.tp2_row.best('feature_type') == 'RegulatoryFeature'
            data.tp2_row.candidate('title_feature_type','Regulatory Feature',80)
          true

        data.tp2_row.register 1000, () ->
          reg_what = data.tp2_row.best('reg_what')
          reg_from = data.tp2_row.best('reg_from')
          if reg_from
            from = expand_for_title[reg_from] ? reg_from
            data.tp2_row.add_value('bracketed-title',from,260)
          if reg_what
            what = expand_for_title[reg_what] ? reg_what
            data.tp2_row.add_value('bracketed-title',what,280)
          #
          for from, to of expand_for_desc
            if reg_what == from then reg_what = to
            if reg_from == from then reg_from = to
          data.tp2_row.candidate('reg_what_desc',reg_what,100)
          data.tp2_row.candidate('reg_from_desc',reg_from,100)
          true

        data.tp2_row.register 2000, () -> 
          reg_from = data.tp2_row.best('reg_from')
          if not reg_from then return
          c = (format[reg_from.toLowerCase()]  ? format._default)
            .replace(/\{(.*?)\}/g,((g0,g1) -> data.tp2_row.best(g1)))
            .replace(/\$(.*?)\$/g,((g0,g1) -> _lc(g1)))
            .replace(/\[(.*?)\]/g,((g0,g1) -> _a(g1)))
          data.tp2_row.add_value('new-contents',c,100)
          data.tp2_row.candidate('description','',500)
          true
    ] 


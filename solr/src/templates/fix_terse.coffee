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

verbose =
  Documentation:
    id: '{subtype} #'
    title: '{article_title}'

_make_string = (r,template) ->
  failed = false 
  out = template.replace /\{(.*?)\}/g,(g0,g1) ->
    v = r.best(g1)
    if not v? then failed = true
    return v
  if failed then return undefined
  return out

window.fixes ?= {}
window.fixes.fix_terse =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 100, () -> # Subtypes for doucmentation
          url = data.tp2_row.best('domain_url')
          url = url.replace(/https?:\/\/.*?\//,'/')
          if url != '' and url[0] != '/'
            url = '/' + url
          data.tp2_row.candidate('url',url,500)
          ft = data.tp2_row.best('feature_type')
          if url
            data.tp2_row.candidate('subtype','ID',10)
            m = url.match /Help\/([a-zA-z]+)/
            if m?
              data.tp2_row.candidate('subtype',m[1],100)

        data.tp2_row.register 150, () -> # Better IDs for doucmentation
          if data.tp2_row.best('feature_type') == 'Documentation'
            data.tp2_row.candidate('id',data.tp2_row.best('url'),100)

        data.tp2_row.register 300, () -> # Overly terse titles
          ft = data.tp2_row.best('feature_type')
          v = verbose[ft]
          if v?.title?
            t = data.tp2_row.best('main-title')
            title = _make_string(data.tp2_row,v.title)
            data.tp2_row.candidate('main-title',title,300)
          if v?.id?
            id = data.tp2_row.best('id')
            id = _make_string(data.tp2_row,v.id) + id
            data.tp2_row.candidate('id',id,300)
        true
    ]


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

_list_string = (singular,plural,data,tail,flip,wrap) ->
  head = (if data.length > 1 then plural else singular)
  tail ?= ''
  wrap ?= ''
  if not $.isArray(wrap) then wrap = [wrap,wrap]
  if flip then [head,tail] = [tail,head]
  data = ( wrap[0]+d+wrap[1] for d in data )
  if data.length == 0 then return ''
  if data.length == 1 then return $.trim([head,data[0],tail].join(' '))
  end = data.pop()
  return $.trim([head,(data.join(', ')),'and',end,tail].join(' '))

title_type = {
  CNV: 'CNV Probe'
  DGVa: 'DGVa'
}

window.fixes ?= {}
window.fixes.fix_g_variation =
  fixes:
    global: [
      (data) ->
        data.tp2_row.register 100, () ->
          ft = data.tp2_row.best('feature_type')
          if $.inArray(ft,["Variation","Somatic Mutation"]) != -1
            desc = data.tp2_row.best('description')
            extract = (re,key) ->
              out = undefined
              desc = desc.replace(re,((g0,g1) => out = g1 ; ''))
              out
            source = extract(/A (.*?) (Variation|Somatic Mutation)\. /)
            phenotypes = extract(/Phenotype\(s\): (.*?)\./)
            genes = extract(/Gene Association\(s\): (.*?)\./)
            if phenotypes?
              for p,i in phenotypes.split(';') 
                data.tp2_row.add_value('v-phenotypes-raw',p,i*100+500)
            if genes?
              for g,i in genes.split(',')
                data.tp2_row.add_value('v-genes',g,i*100+500)
            if desc.match /\w/
              data.tp2_row.add_value('new-contents',desc,100)
              data.tp2_row.candidate('description','',900)
            data.tp2_row.candidate('v-source',source,100)
          else if ft == 'Phenotype'
            desc = data.tp2_row.best('description')
            name = data.tp2_row.best('name')
            title = desc?.replace(/\.$/,'')
            title ?= name.toLowerCase()
            data.tp2_row.candidate('main-title',title,200)
          else if ft == 'StructuralVariation'
            data.tp2_row.candidate('title_feature_type','Structural Variation',200)
            desc = data.tp2_row.best('description')
            re = /A structural variation from (.*?)\, identified by (.*)$/
            m = desc.match(re)
            if m?
              data.tp2_row.candidate('sv-source',m[1],100)
              n = m[2].replace(/\(study (.*)\)/,'')
              if n?
                data.tp2_row.candidate('sv-study',n[1],100)
              data.tp2_row.candidate('sv-method',m[2],100)
              type = undefined
              for pattern,t of title_type
                if m[1].indexOf(pattern) != -1
                  type = t
              if type then data.tp2_row.add_value('bracketed-title',type,290)

        # Standardise phenotypes
        data.tp2_row.register 500, () ->
          vpr = data.tp2_row.all_values('v-phenotypes-raw')
          if not vpr then return
          vpr = ( k.value for k in vpr.sort((a,b) -> a.position - b.position) )
          cosmic = {}
          forms = {}
          for p in vpr
            m = p.match(/(COSMIC):(tumour_site):(.*)/)
            if m?
              cosmic[m[2]] ?= []
              cosmic[m[2]].push(m[3])
            else if p.match(/HGMD_MUTATION/)
              data.tp2_row.add_value('new-contents', "<i>Annotated by HGMD but no phenotype description is publicly available (HGMD_MUTATION)</i>",5000)
            else
              # Neither COSMIC nor HGMD_MUTATION
              parts = ($.trim(x) for x in p.toLowerCase().split(','))
              std = parts.sort((a,b) -> a.localeCompare(b)).join(' ')
                .replace(/\s+/g,' ')
              if (not forms[std]?) or forms[std][1] > parts.length
                forms[std] = [p,parts.length]
          vp = ( v[0] for k,v of forms )
          for p,i in vp
            if p.toUpperCase() == p
              vp[i] = p.charAt(0)+p.substring(1).toLowerCase()
          data.tp2_row.add_value('v-phenotypes',p,200+i) for p in vp
          i = 0
          for ctype,csites of cosmic
            type = ctype.replace(/_/g,' ')
            i += 1
            str = "Associated with COSMIC "+
              _list_string(type,type+"s",csites,'',false,'"')
            data.tp2_row.add_value('new-contents',str,4000+i)
        
        data.tp2_row.register 1000, () ->
          # Source
          vs = data.tp2_row.best('v-source')
          if vs
            vs = vs.replace(/_/g,' ')
            data.tp2_row.add_value('bracketed-title',vs,255)
          # Description
          assocs = []
          vp = data.tp2_row.all_values('v-phenotypes')
          if vp
            vp = ( k.value for k in vp.sort((a,b) -> a.position - b.position))
            assocs.push(_list_string("phenotype","phenotypes",vp,'',true,'"'))
          vg = data.tp2_row.all_values('v-genes')
          if vg and vg.length
            vg = ( k.value for k in vg.sort((a,b) -> a.position - b.position))
            assocs.push(_list_string("gene","genes",vg))
          if assocs.length
            data.tp2_row.add_value('new-contents',"Associated with "+assocs.join(' and '),10)
        true 
    ] 


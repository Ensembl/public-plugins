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
        data.tp2_row.register 300, () ->
          ft = data.tp2_row.best('feature_type')
          if ft == 'Domain' or ft == 'Family'
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
          if ft == 'Domain'
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


<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$query_species</span> <span class="comp_tut opt">=</span> <span class="comp_tut str">'human'</span><span class="comp_tut opt">;</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$seq_region</span> <span class="comp_tut opt">=</span> <span class="comp_tut str">'14'</span><span class="comp_tut opt">;</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$seq_region_start</span> <span class="comp_tut opt">=</span> <span class="comp_tut num">75000000</span><span class="comp_tut opt">;</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$seq_region_end</span>   <span class="comp_tut opt">=</span> <span class="comp_tut num">75010000</span><span class="comp_tut opt">;</span>

<span class="comp_tut slc"># Getting the Slice adaptor:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$slice_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span>
    <span class="comp_tut kwb">$query_species</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'core'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'Slice'</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># Fetching a Slice object:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$query_slice</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$slice_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_region</span><span class="comp_tut opt">(</span>
    <span class="comp_tut str">'toplevel'</span><span class="comp_tut opt">,</span>
    <span class="comp_tut kwb">$seq_region</span><span class="comp_tut opt">,</span>
    <span class="comp_tut kwb">$seq_region_start</span><span class="comp_tut opt">,</span>
    <span class="comp_tut kwb">$seq_region_end</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># Fetching all the GenomicAlignBlock corresponding to this Slice from the pairwise alignments (LASTZ_NET)</span>
<span class="comp_tut slc"># between human and mouse:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$genomic_align_blocks</span> <span class="comp_tut opt">=</span>
    <span class="comp_tut kwb">$genomic_align_block_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_all_by_MethodLinkSpeciesSet_Slice</span><span class="comp_tut opt">(</span>
      <span class="comp_tut kwb">$human_mouse_lastz_net_mlss</span><span class="comp_tut opt">,</span>
      <span class="comp_tut kwb">$query_slice</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># We will then (usually) need to restrict the blocks to the required positions in the reference sequence </span>
<span class="comp_tut slc"># ($seq_region_start and $seq_region_end)</span>

<span class="comp_tut kwa">foreach</span> <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$genomic_align_block</span><span class="comp_tut opt">(</span> &#64;<span class="comp_tut opt">{</span> <span class="comp_tut kwb">$genomic_align_blocks</span> <span class="comp_tut opt">}) {</span>
    <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$restricted_gab</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$genomic_align_block</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">restrict_between_reference_positions</span><span class="comp_tut opt">(</span><span class="comp_tut kwb">$seq_region_start</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$seq_region_end</span><span class="comp_tut opt">);</span>
<span class="comp_tut opt">}</span>

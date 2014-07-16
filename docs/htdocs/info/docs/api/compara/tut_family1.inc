<span class="comp_tut slc"># Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute</span>
<span class="comp_tut slc"># </span>
<span class="comp_tut slc"># Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);</span>
<span class="comp_tut slc"># you may not use this file except in compliance with the License.</span>
<span class="comp_tut slc"># You may obtain a copy of the License at</span>
<span class="comp_tut slc"># </span>
<span class="comp_tut slc">#      http://www.apache.org/licenses/LICENSE-2.0</span>
<span class="comp_tut slc"># </span>
<span class="comp_tut slc"># Unless required by applicable law or agreed to in writing, software</span>
<span class="comp_tut slc"># distributed under the License is distributed on an &quot;AS IS&quot; BASIS,</span>
<span class="comp_tut slc"># WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.</span>
<span class="comp_tut slc"># See the License for the specific language governing permissions and</span>
<span class="comp_tut slc"># limitations under the License.</span>

<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$gene_member_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span><span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'GeneMember'</span><span class="comp_tut opt">);</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$gene_member</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$gene_member_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_stable_id</span><span class="comp_tut opt">(</span><span class="comp_tut str">'ENSG00000004059'</span><span class="comp_tut opt">);</span>

<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$family_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span><span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span><span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span><span class="comp_tut str">'Family'</span><span class="comp_tut opt">);</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$families</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$family_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_all_by_Member</span><span class="comp_tut opt">(</span><span class="comp_tut kwb">$gene_member</span><span class="comp_tut opt">);</span>

<span class="comp_tut kwa">foreach</span> <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$family</span> <span class="comp_tut opt">(</span>&#64;<span class="comp_tut opt">{</span><span class="comp_tut kwb">$families</span><span class="comp_tut opt">}) {</span>
    <span class="comp_tut kwc">print join</span><span class="comp_tut opt">(</span><span class="comp_tut str">&quot; &quot;</span><span class="comp_tut opt">,</span> <span class="comp_tut kwc">map</span> <span class="comp_tut opt">{</span> <span class="comp_tut kwb">$family</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwb">$_</span> <span class="comp_tut opt">}</span>  <span class="comp_tut kwc">qw</span><span class="comp_tut opt">(</span>description description_score<span class="comp_tut opt">)).</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>

    <span class="comp_tut kwa">foreach</span> <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$member</span> <span class="comp_tut opt">(</span>&#64;<span class="comp_tut opt">{</span><span class="comp_tut kwb">$family</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_all_Members</span><span class="comp_tut opt">}) {</span>
        <span class="comp_tut kwc">print</span> <span class="comp_tut kwb">$member</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">stable_id</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot; &quot;</span><span class="comp_tut opt">,</span><span class="comp_tut kwb">$member</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">taxon_id</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>
    <span class="comp_tut opt">}</span>

    <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$simple_align</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$family</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_SimpleAlign</span><span class="comp_tut opt">();</span>
    <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$alignIO</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>AlignIO<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">newFh</span><span class="comp_tut opt">(</span>
        <span class="comp_tut opt">-</span>interleaved <span class="comp_tut opt">=&gt;</span> <span class="comp_tut num">0</span><span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>fh          <span class="comp_tut opt">=&gt;</span> \<span class="comp_tut opt">*</span>STDOUT<span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>format      <span class="comp_tut opt">=&gt;</span> <span class="comp_tut str">&quot;phylip&quot;</span><span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>idlength    <span class="comp_tut opt">=&gt;</span> <span class="comp_tut num">20</span><span class="comp_tut opt">);</span>

    <span class="comp_tut kwc">print</span> <span class="comp_tut kwb">$alignIO $simple_align</span><span class="comp_tut opt">;</span>

    <span class="comp_tut kwb">$simple_align</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$family</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_SimpleAlign</span><span class="comp_tut opt">(-</span>seq_type <span class="comp_tut opt">=&gt;</span> <span class="comp_tut str">'cds'</span><span class="comp_tut opt">);</span>
    <span class="comp_tut kwb">$alignIO</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>AlignIO<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">newFh</span><span class="comp_tut opt">(</span>
        <span class="comp_tut opt">-</span>interleaved <span class="comp_tut opt">=&gt;</span> <span class="comp_tut num">0</span><span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>fh          <span class="comp_tut opt">=&gt;</span> \<span class="comp_tut opt">*</span>STDOUT<span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>format      <span class="comp_tut opt">=&gt;</span> <span class="comp_tut str">&quot;phylip&quot;</span><span class="comp_tut opt">,</span>
        <span class="comp_tut opt">-</span>idlength    <span class="comp_tut opt">=&gt;</span> <span class="comp_tut num">20</span><span class="comp_tut opt">);</span>

    <span class="comp_tut kwc">print</span> <span class="comp_tut kwb">$alignIO $simple_align</span><span class="comp_tut opt">;</span>
<span class="comp_tut opt">}</span>

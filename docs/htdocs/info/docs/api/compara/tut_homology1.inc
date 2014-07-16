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

<span class="comp_tut slc"># first you have to get a GeneMember object. In case of homology is a gene, in </span>
<span class="comp_tut slc"># case of family it can be a gene or a protein</span>

<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$gene_member_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span><span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'GeneMember'</span><span class="comp_tut opt">);</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$gene_member</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$gene_member_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_stable_id</span><span class="comp_tut opt">(</span><span class="comp_tut str">'ENSG00000004059'</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># then you get the homologies where the member is involved</span>

<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$homology_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span><span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'Homology'</span><span class="comp_tut opt">);</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$homologies</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$homology_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_all_by_Member</span><span class="comp_tut opt">(</span><span class="comp_tut kwb">$gene_member</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># That will return a reference to an array with all homologies (orthologues in</span>
<span class="comp_tut slc"># other species and paralogues in the same one)</span>
<span class="comp_tut slc"># Then for each homology, you can get all the Members implicated</span>

<span class="comp_tut kwa">foreach</span> <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$homology</span> <span class="comp_tut opt">(</span>&#64;<span class="comp_tut opt">{</span><span class="comp_tut kwb">$homologies</span><span class="comp_tut opt">}) {</span>
  <span class="comp_tut slc"># You will find different kind of description</span>
  <span class="comp_tut slc"># see ensembl-compara/docs/docs/schema_doc.html for more details</span>

  <span class="comp_tut kwc">print</span> <span class="comp_tut kwb">$homology</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">description</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot; &quot;</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$homology</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">taxonomy_level</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>

  <span class="comp_tut slc"># And if they are defined dN and dS related values</span>

  <span class="comp_tut kwc">print</span> <span class="comp_tut str">&quot; dn &quot;</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$homology</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">dn</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>
  <span class="comp_tut kwc">print</span> <span class="comp_tut str">&quot; ds &quot;</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$homology</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">ds</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>
  <span class="comp_tut kwc">print</span> <span class="comp_tut str">&quot; dnds_ratio &quot;</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$homology</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">dnds_ratio</span><span class="comp_tut opt">,</span><span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>
<span class="comp_tut opt">}</span>

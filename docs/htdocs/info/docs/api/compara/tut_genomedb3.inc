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

<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$all_genome_dbs</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$genome_db_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_all</span><span class="comp_tut opt">();</span>
<span class="comp_tut kwa">foreach</span> <span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$this_genome_db</span> <span class="comp_tut opt">(</span>&#64;<span class="comp_tut opt">{</span><span class="comp_tut kwb">$all_genome_dbs</span><span class="comp_tut opt">}) {</span>
  <span class="comp_tut kwc">print</span> <span class="comp_tut kwb">$this_genome_db</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">name</span><span class="comp_tut opt">,</span> <span class="comp_tut str">&quot;</span><span class="comp_tut esc">\n</span><span class="comp_tut str">&quot;</span><span class="comp_tut opt">;</span>
<span class="comp_tut opt">}</span>

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

<span class="comp_tut slc"># Getting the GenomeDB adaptor:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$genome_db_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span>
    <span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'GenomeDB'</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># Fetching GenomeDB objects for human and mouse:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$human_genome_db</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$genome_db_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_name_assembly</span><span class="comp_tut opt">(</span><span class="comp_tut str">'homo_sapiens'</span><span class="comp_tut opt">);</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$mouse_genome_db</span> <span class="comp_tut opt">=</span> <span class="comp_tut kwb">$genome_db_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_name_assembly</span><span class="comp_tut opt">(</span><span class="comp_tut str">'mus_musculus'</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># Getting the MethodLinkSpeciesSet adaptor:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$method_link_species_set_adaptor</span> <span class="comp_tut opt">=</span> Bio<span class="comp_tut opt">::</span>EnsEMBL<span class="comp_tut opt">::</span>Registry<span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">get_adaptor</span><span class="comp_tut opt">(</span>
    <span class="comp_tut str">'Multi'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'compara'</span><span class="comp_tut opt">,</span> <span class="comp_tut str">'MethodLinkSpeciesSet'</span><span class="comp_tut opt">);</span>

<span class="comp_tut slc"># Fetching the MethodLinkSpeciesSet object corresponding to LASTZ_NET alignments between human and mouse genomic sequences:</span>
<span class="comp_tut kwc">my</span> <span class="comp_tut kwb">$human_mouse_lastz_net_mlss</span> <span class="comp_tut opt">=</span>
    <span class="comp_tut kwb">$method_link_species_set_adaptor</span><span class="comp_tut opt">-&gt;</span><span class="comp_tut kwd">fetch_by_method_link_type_GenomeDBs</span><span class="comp_tut opt">(</span>
        <span class="comp_tut str">&quot;LASTZ_NET&quot;</span><span class="comp_tut opt">,</span>
        <span class="comp_tut opt">[</span><span class="comp_tut kwb">$human_genome_db</span><span class="comp_tut opt">,</span> <span class="comp_tut kwb">$mouse_genome_db</span><span class="comp_tut opt">]</span>
    <span class="comp_tut opt">);</span>

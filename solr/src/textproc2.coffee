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

class TextProc2
  constructor: () ->
    @candidates = {}
    @values = {}
    @running = []

  ## CANDIDATES ##
  candidate: (key,value,priority) ->
    if not priority? then priority = @candidates[key]?.priority ? 0
    if not value? then return
    if (not @candidates[key]?) or @candidates[key].priority < priority
      @candidates[key] = { value, priority }
  
  best: (key) -> @candidates[key]?.value

  ## VALUE SETS ##
  add_value: (key,value,position) ->
    if not @values[key] then @values[key] = []
    @values[key].push({value, position})

  all_values: (key) -> @values[key]

  ## OUTPUT ##
  send: (key,value) -> @output[key] = value

  ## RUNNING ##
  register: (prio,method) ->
    @running.push({prio, method })

  _sort_running: () ->
    return (r.method for r in @running.sort((a,b) -> a.prio - b.prio))

  run: (data) ->
    @candidates = {}
    @values = {}
    @output = {}
    @candidate(k,v,0) for k,v of data
    for r in @_sort_running()
      r.call(@)
    return @output

window.TextProc2 = TextProc2


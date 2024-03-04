/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.BlastForm = Ensembl.Panel.ToolsForm.extend({
  constructor: function () {
    this.base.apply(this, arguments);

    this.sequences          = [];
    this.selectedQueryType  = false;
    Ensembl.EventManager.register('resetSearchTools', this, this.resetSearchTools);
    Ensembl.EventManager.register('resetSourceTypes', this, this.resetSourceTypes);

  },

  init: function () {
    var panel = this;

    this.base.apply(this, arguments);

    // Gets config values from js_params
    this.combinations         = this.params['valid_combinations'];
    this.restrictions         = this.params['restrictions'];
    this.missingSources       = this.params['missing_sources'];
    this.blatAvailability     = this.params['blat_availability'];
    this.sensitivityConfigs   = this.params['sensitivity_configs'];
    this.maxSequenceLength    = this.params['max_sequence_length'];
    this.maxNumSequences      = this.params['max_number_sequences'];
    this.dnaThresholdPercent  = this.params['dna_threshold_percent'];
    this.readFileURL          = this.params['read_file_url'];
    this.fetchSequenceURL     = this.params['fetch_sequence_url'];
    this.blat_value           = 'BLAT_BLAT';
    this.searchToolUserSelection;
    this.sourceRemoved = [];

    // nothing can be done if any of these is missing!
    if (!this.combinations || !this.maxSequenceLength || !this.dnaThresholdPercent || !this.maxNumSequences) {
      this.showError('JavaScript error occurred while initiating the Blast form.', 'Blast form error');
      return;
    }

    // sequence input fields
    this.elLk.sequences     = this.elLk.form.find('div._sequence');
    this.elLk.sequenceField = this.elLk.form.find('div._sequence_field');

    // rna message flag
    this.rnaMessageDisplayed = false;

    // provide event handlers to the textarea where sequence text is typed
    var sequenceInputEvent = function(e) { // add some delay to make sure the blur event actually gets fired after making sure some other event hasn't removed the input string
      var element = $(this).off('blur change paste'); // prevent all events to fire at once
      setTimeout(function() {
        element.trigger('finish').trigger('blur').on('blur change paste', sequenceInputEvent);
        element = null;
      }, 100);
    };
    this.elLk.sequenceInput = this.elLk.form.find('textarea[name=query_sequence]').on({
      'focus': function(e) {
        if (!this.value || this.value === this.defaultValue) {
          $(this).val('').removeClass('inactive');
        }
      },
      'finish': function() {
        this.value = this.value.trim();
        if (this.value && this.value !== this.defaultValue) {
          panel.addSequenceByID(this.value) || panel.addSequences(this.value);
        } else {
          $(this).val(this.defaultValue).addClass('inactive');
        }
      },
      'blur change paste': sequenceInputEvent
    });

    // close botton to hide the sequence textarea
    this.elLk.sequenceInputClose = this.elLk.sequenceInput.prev().on('click', function() {
      panel.toggleSequenceFields(false);
      panel.updateSeqInfo(true);
    });

    // if any file is added to the file field, read it and display the sequence
    this.elLk.queryFile = this.elLk.form.find('input[name=query_file]').on({
      'click': function() { // this is to prevent the blur event on sequenceInput from adding the currently added text as sequence
        panel.elLk.sequenceInput.val('');
      },
      'change': function() {
        if (window.FileList && window.File && window.FileReader) {
          if (!panel.fileReader) { // to avoid multiple instances
            panel.fileReader = new FileReader();
          }
          panel.fileReader.onload = function(readerEvent) {
            panel.addSequences(readerEvent.target.result);
            panel.toggleSpinner(false);
            panel.elLk.queryFile.val('');
          };
          panel.fileReader.onerror = function(readerEvent) {
            pabel.showError(readerEvent.target.error.code, "Error reading file");
            panel.toggleSpinner(false);
          };
          panel.toggleSpinner(true);
          panel.fileReader.readAsText(this.files[0]);
        } else {
          panel.ajax({
            'url'     : panel.readFileURL,
            'iframe'  : true,
            'form'    : panel.elLk.form,
            'spinner' : true,
            'success' : function(json) {
              if ('file_error' in json) {
                this.showError(json['file_error']);
              } else if ('file' in json) {
                this.addSequences(json['file']);
              }
            },
            'complete': function() {
              this.elLk.queryFile.val('');
            }
          });
        }
      }
    });

    // Query type radio button
    this.elLk.queryType = this.elLk.form.find('input[name=query_type]').on('change', function() {
      panel.setQueryTypeValue(this.value);
    }).first().prop('checked', true).end();

    // DB type radio buttons
    this.elLk.dbType = this.elLk.form.find('input[name=db_type]').on('click', function() {
      panel.resetSearchTools();
    }).first().prop('checked', true).end();

    // Source type dropdown
    this.elLk.source = this.elLk.form.find('select[name^=source_]').on('change', function() {
      panel.elLk.dbType.filter('[value=' + this.name.split('_')[1] + ']').prop('checked', true);
      panel.resetSearchTools();
    });

    // Search type dropdown
    this.elLk.searchType = this.elLk.form.find('select[name=search_type]').on('change', function(event) {
      panel.setSensitivityConfigs($(this).find('option:selected').val());
      if(event.originalEvent) {
        panel.searchToolUserSelection = $(this).find('option:selected').val();
      }
    });
    this.elLk.searchTypeOptions = this.elLk.searchType.find('option').clone(); // take a copy to preserve a list of all supported search types

    // Search sensitivity
    this.elLk.sensitivityOptions = this.elLk.form.find('select[name^=config_set_]').on('change', function() {
      panel.setSensitivityConfigs($(this));
    });

    // finally add a validate event to the form which gets triggered before submitting it
    this.elLk.form.on('validate', function(e) {
      if (!panel.sequences.length) {
        panel.elLk.sequenceInput.trigger('finish');
      }
      if (!panel.sequences.length) {
        panel.showError('Please provide a sequence to run BLAST/BLAT.', 'No sequence found');
        $(this).data('valid', false);
        return;
      }

      if (!panel.getSelectedSpecies().length) {
        panel.showError('Please select a species to run BLAST/BLAT against.', 'No species selected');
        $(this).data('valid', false);
        return;
      }
    });

    // Show only the appropriate search types depending upon the default selected values for query type and db type source
    this.resetSearchTools(this.blatAvailability[this.defaultSpecies] ? this.blat_value : '');  
    
    this.resetSourceTypes([ this.defaultSpecies ]);

    // Select species
    this.resetSpecies([ this.defaultSpecies ]);

    // Fill in the form if editing an existing job
    this.editExisting(true);
  },

  reset: function() {
  /*
   * Resets the form, ready to accept next job input
   */

    this.base.apply(this, arguments);

    // Reset sequences
    for (var i = this.sequences.length - 1; i >= 0; i--) {
      this.sequences[i].destructor();
    }
    this.sequences = [];
    this.updateSeqInfo(false);
    this.toggleSequenceFields(true);

    // Reset query type, db type and source type to first option, then set search tool accordingly
    this.selectedQueryType = false;
    this.elLk.queryType.first().prop('checked', true);
    this.elLk.dbType.first().prop('checked', true);
    this.elLk.source.find('option').first().prop('selected', true);
    this.resetSearchTools();
    this.searchToolUserSelection = '';
    // Reset species
    this.resetSpecies([ this.defaultSpecies ]);
  },

  populateForm: function(jobsData) {
  /*
   * Populates the form according to the provided ticket data
   */
    this.reset();
    var formInput = {};
    var speciesListMap = {};
    if (jobsData.length) {
      for (var i = jobsData.length - 1; i >= 0; i--) {
        for (var paramName in jobsData[i]) {
          if (paramName === 'sequence' || paramName === 'species') {
            if (!(paramName in formInput)) {
              formInput[paramName] = [];
            }
            if (paramName === 'species') {
              // Making a uniq species list
              !speciesListMap[jobsData[i][paramName]] && formInput[paramName].unshift(jobsData[i][paramName]);
              speciesListMap[jobsData[i][paramName]] = 1;
            }
            else {
              formInput[paramName].unshift(jobsData[i][paramName]);
            }
          } else {
            formInput[paramName] = jobsData[i][paramName];
          }
        }
      }
    }

    if (!$.isEmptyObject(formInput)) {
      this.toggleForm(true);

      // set sequence and query type
      if (formInput['query_type']) {
        this.addEditingJobSequences(formInput['sequence'], formInput['query_type']);
      } else {
        // in case sequence is recieved from 'BLAST this sequence' link, it doesn't have query_type
        // it could possible be a seq/accession id in that case
        this.addSequenceByID(formInput['sequence'][0]['sequence']) || this.addSequences(formInput['sequence'][0]['sequence']);
      }

      // set db type, source and search type
      this.elLk.form.find('[name=db_type][value=' + formInput['db_type'] + ']').prop('checked', true);
      this.elLk.form.find('[name^=source_] option[value=' + formInput['source'] + ']').prop('selected', true);
      if (formInput['search_type']) {
        this.searchToolUserSelection = formInput['search_type'];
      }
      this.resetSearchTools(formInput['search_type']);

      // set species
      this.resetSpecies(formInput['species'] || [ this.defaultSpecies ]);

      // set sensitivity
      if(formInput['config_set']){
        this.elLk.form.find('[name=config_set_' + formInput['search_type']+ ']').find('option[value="' + formInput['config_set'] + '"]').prop('selected', true).end().selectToToggle('trigger');
      }

      if (formInput['configs']) {
        for (var name in formInput['configs']) {
          this.elLk.form.find('[name=' + formInput['search_type'] + '__' + name + ']')
            .filter('input[type=checkbox]').prop('checked', !!formInput['configs'][name]).end()
            .filter('select').find('option[value="' + formInput['configs'][name] + '"]').prop('selected', true).end().selectToToggle('trigger');
        }
      }
    }
  },

  addSequences: function(rawText, existingSequence) {
  /*
   * Adds new sequences to the page from the raw text entered by the user
   * If editing an existing job, it replaces the existing one, and adds new ones if required
   */

    var parsedSeqs        = this.parseRawSequences(rawText);
    var duplicates        = 0;
    var modifyingExisting = !!existingSequence;
    var numParsedSeqs     = parsedSeqs.sequences.length;
    var numSeqs           = this.sequences.length;
    var indexParsedSeq    = 0;
    var indexSeq;

    seqLoop:
    for (indexParsedSeq = 0; indexParsedSeq < numParsedSeqs; indexParsedSeq++) {
      for (indexSeq = 0; indexSeq < numSeqs; indexSeq++) {
        if (parsedSeqs.sequences[indexParsedSeq].string === this.sequences[indexSeq].string && !(existingSequence && this.sequences[indexSeq] === existingSequence)) {
          duplicates++;
          if (modifyingExisting && numParsedSeqs === 1) { // editing a sequence, and only one sequence parsed, that too is a duplicate now
            this.removeSequence(existingSequence);
          }
          continue seqLoop;
        }
      }
      if (modifyingExisting) {
        existingSequence.init(parsedSeqs.sequences[indexParsedSeq]);
        modifyingExisting = false; // now since the existing one is replaced, the new ones do not need to replace the exisitng one again, but need to be inserted next to the existing one
      } else {
        if (numSeqs >= this.maxNumSequences) {
          break;
        }
        this.sequences.splice(existingSequence && this.sequences.indexOf(existingSequence) + 1 || numSeqs, 0, new Ensembl.Class.BlastFormSequence(parsedSeqs.sequences[indexParsedSeq], this, existingSequence || false));
      }
      numSeqs = this.sequences.length;
    }

    if (numSeqs) {
      this.setQueryTypeValue(); // let it decide the query type itself
      this.toggleSequenceFields(false);
    }

    this.updateSeqInfo({'added': indexParsedSeq - duplicates, 'invalids': parsedSeqs.invalids + duplicates, 'is_rna': parsedSeqs.is_rna});

    parsedSeqs = duplicates = modifyingExisting = numParsedSeqs = numSeqs = indexSeq = null;

    return indexParsedSeq;
  },

  addSequenceByID: function(seqId) {
  /* Fetches a sequence by seq id or accession id and then adds it to the textarea
   * @param Seq id or accession id
   * @return false it seq id or accession id is invalid, true otherwise
   */
    if (this.fetchSequenceURL && seqId.match(/[0-9]+/) && seqId.match(/^[a-z]{1}[a-z0-9\.\-\_]{4,30}$/i)) {
      this.ajax({
        'comet'   : true,
        'url'     : this.fetchSequenceURL,
        'data'    : { id: seqId },
        'spinner' : true,
        'update'  : function(json) {
          this.toggleSpinner(true, 'Fetching sequence&#8230;');
        }
      });
      return true;
    }
    return false;
  },

  parseRawSequences: function(rawText) {
  /*
   * Parses raw text into fasta sequences, possibly multiple fasta sequences
   * @return Object with following keys
   *  sequences: Array of objects each containing three keys: type, description and string
   *  invalids: number of invalid or duplicate sequences ignored
   */
    var bases           = 'ACTUGNX';
    var inputSeqs       = rawText.replace(/^[\s\n\t]+|[\s\n\t]+$/g, '').split(/(?=>)|\n+[\s\t]*\n+/); // '>' or an empty line represents start of a new sequence
    var sequences       = [];
    var isRNA           = false;

    var sequenceLines, pointer, seqLine, seqChar, seqDNACharCount, i, j;

    // if input sequence was copied from a web page, it could contain spaces instead of new line characters
    var spaceToNewLine = function(seqLines) {

      var seqIn, seqOut = [], only60char = false, seq;

      if (seqLines.length === 1 && seqLines[0].match(/^>/)) { // if it looks like only header text is pasted, it could contian the entire sequence with new lines replaced with spaces
        seqIn = seqLines[0].split(/[\s\t]+/);
        while (seqIn.length) {
          seq = seqIn.pop();
          if (seq.match(/^[A-Z\*\-]+$/i) && (!only60char || seq.length === 60)) {
            seqOut.unshift(seq);
          } else {
            seqIn.push(seq);
            break;
          }
          only60char = true; // only last line of the possible sequence could be less than 60 characters
        }
        seqOut.unshift(seqIn.join(' ')); // remaining text is header
      }

      seqIn = only60char = seq = null;

      return seqOut.length > 1 ? seqOut : seqLines;
    };

    rawSeqLoop:
    for (i = 0; i < inputSeqs.length; i++) {
      sequenceLines   = spaceToNewLine(inputSeqs[i].trim().split(/[\s\t]*\n[\s\t]*/));
      pointer         = 0;
      seqDNACharCount = 0;
      seqString       = '';
      sequence        = {'string': '', 'description': '>', 'type': ''};

      seqLineLoop:
      for (j = 0; j < sequenceLines.length; j++) {
        seqLine = sequenceLines[j];
        pointer = 0;
        if (seqLine.match(/^(>|\;)/)) {
          if (j === 0) { // it's description if it's the first line, otherwise ignore, as it's a comment
            sequence.description = seqLine.replace(/^(>|\;)(\s\t)+/, '');
          }
        } else {
          seqLine = seqLine.toUpperCase().replace(/[^A-Z\*\-]+/, '');
          while (pointer < seqLine.length) {
            seqChar = seqLine.charAt(pointer);
            if (pointer === this.maxSequenceLength) {
              break seqLineLoop;
            }
            if (!seqChar.match(/\d|\s|\t/)) {
              if (bases.indexOf(seqChar) >= 0) {
                seqDNACharCount++;

                if (seqChar === 'U') {
                  isRNA = true;
                }
              }
              sequence.string += seqChar;
            }
            pointer++;
          }
        }
      }
      if (sequence.string === '') {
        continue rawSeqLoop;
      }

      sequence.type = 100 * seqDNACharCount / sequence.string.length < this.dnaThresholdPercent ? 'peptide' : 'dna';

      // skip if it's a duplicate, or invalid sequence
      for (j = 0; j < sequences.length; j++) {
        if (sequences[j].string === sequence.string) {
          continue rawSeqLoop;
        }
      }

      // invalid sequence
      if (!sequence.string.match(/^[A-Z\*]+$/)) {
        continue rawSeqLoop;
      }

      if (isRNA === true) {
        sequence.string = sequence.string.replace(/U/g, 'T');
      }

      sequences.push(sequence);

      if (sequences.length >= this.maxNumSequences) { // already added sequences are not considered in this count as there might be some duplicates that get removed later on.
        break rawSeqLoop;
      }
    }

    bases = inputSeqs = sequenceLines = pointer = seqLine = seqChar = seqDNACharCount = j = spaceToNewLine = null;

    return {'sequences': sequences, 'invalids': i - sequences.length, 'is_rna': isRNA};
  },

  addEditingJobSequences: function(editingJobSequences, type) {
  /*
   * Adds the sequences from the data received from the backend for a job that needs to be edited
   */
    seqLoop:
    for (var i = 0; i < editingJobSequences.length; i++) {
      for (var j = this.sequences.length - 1; j >= 0; j--) {
        if (editingJobSequences[i]['sequence'] === this.sequences[j].string) {
          continue seqLoop;
        }
      }
      if (this.sequences.length >= this.maxNumSequences) {
        break;
      }
      this.sequences.push(new Ensembl.Class.BlastFormSequence({
        'string'      : editingJobSequences[i]['sequence'],
        'description' : '>' + (editingJobSequences[i]['display_id'] || ''),
        'type'        : type
      }, this, false));
    }

    if (this.sequences.length) {
      this.setQueryTypeValue(type);
      this.toggleSequenceFields(false);
    }

    this.updateSeqInfo({'added': this.sequences.length});

    return this.sequences.length;
  },

  modifySequence: function(sequenceObject, rawText) {
  /*
   * Modifies an existing sequence when edited by the user
   */
    if (rawText && !!this.addSequences(rawText, sequenceObject)) { // if sequence was valid and is successfully modified
      this.updateSeqInfo(true);
      return;
    }

    // remove the sequence otherwise
    this.removeSequence(sequenceObject);
  },

  removeSequence: function(sequenceObject) {
  /*
   * Removes an existing sequence from this panel and dom tree
   */
    this.sequences.splice(this.sequences.indexOf(sequenceObject), 1);
    sequenceObject.destructor();
    var flag = !!this.sequences.length;
    this.updateSeqInfo(flag);
    this.toggleSequenceFields(!flag);
    this.setQueryTypeValue();
  },

  toggleSequenceFields: function(flag) {
  /*
   * Show/hide sequence input box according to the flag provided
   */
    var panel = this;
    this.elLk.sequenceField.toggle(flag);
    this.elLk.sequenceInput.val('').focus();
    if (this.elLk.sequenceInfo) {
      this.elLk.sequenceInfo.toggle(!flag);
    }
    if (flag) {
      this.elLk.sequenceInputClose.toggle(!!this.sequences.length);
      if (!this.sequences.length) {
        this.elLk.sequences.hide();
      }
    }
    this.adjustDivsHeight();
  },

  setQueryTypeValue: function(queryType) {
  /*
   * Sets the query type value according to the one provided, or if no query type is provided, it sets the one with majority number of sequences
   */

    if (queryType) {
      this.selectedQueryType = queryType;
    } else {

      // if a query type has already been selected by the user, that can not be changed!
      queryType = this.selectedQueryType;

      // if any of the options can be selected, check which query type was guessed for more number of sequences
      if (!queryType) {
        var queryTypes = {'peptide': 0, 'dna': 0};
        $.each(this.sequences, function() {
          queryTypes[this.guessedType]++;
        });

        // give preference to already selected one if both are equal
        if (queryTypes.peptide === queryTypes.dna) {
          queryType = this.elLk.queryType.filter(':checked').val();
        } else {
          queryType = queryTypes.peptide < queryTypes.dna ? 'dna' : 'peptide';
        }
      }
    }

    // select the appropriate radio button
    this.elLk.queryType.filter('[value=' + queryType + ']').prop('checked', true);

    // reset the available search tools
    this.resetSearchTools();
  },

  isBlatAvailable: function(selectedSpecies) {
    var panel = this;
    selectedSpecies = selectedSpecies || this.getSelectedSpecies();
    var blat_available = 1;
    $.each(selectedSpecies, function(i, sp) {
      if (!panel.blatAvailability[sp]) {
        blat_available = 0;
        return false;
      }
    });
    return blat_available ? true : false;
  },

  resetSearchTools: function(selectedSearchType, selectedSpecies) {
  /*
   * Resets the search tool dropdown according to the currently selected values of query type, db type and source type
   */
    var panel = this;
    var queryType = this.elLk.queryType.filter(':checked').val();
    var dbType    = this.elLk.dbType.filter(':checked').val();
    var source    = this.elLk.source.filter('[name=source_' + dbType + ']').val();
    var valid     = [];
    var blat      = this.isBlatAvailable(selectedSpecies ? selectedSpecies : this.getSelectedSpecies());

    selectedSearchType = selectedSearchType || (!this.searchToolUserSelection && blat && this.blat_value);
    for (var i = this.combinations.length - 1; i >= 0; i--) {
      if (this.combinations[i]['query_type'] === queryType && this.combinations[i]['db_type'] === dbType && this.combinations[i]['sources'].indexOf(source) >= 0) {
        if (this.sequences.length) {
          for (var j = this.sequences.length -1; j >= 0; j--) {
            if (this.sequences[j].string.length > this.combinations[i]['min_length']) {
              valid.push(this.combinations[i]['search_type']);
            }
          }
        }
        else{
          valid.push(this.combinations[i]['search_type']);
        }
      }
    }

    // now remove the invalid options for the selected combination of query type, db type and source type
    this.elLk.searchType.empty()
      .append(this.elLk.searchTypeOptions.filter(function() { return valid.indexOf(this.value) >= 0; }).clone())
      .find('option[value=' + (selectedSearchType || panel.searchToolUserSelection || '') + ']').prop('selected', true).end().selectToToggle('trigger').trigger('change');
      
    !blat && this.elLk.searchType.find('option[value=' + this.blat_value + ']').remove();

    // removing dbType for different method example you cant do ncrna alignment for tblastn (this only works for source_dna for now)
    // TODO: make the source dropdown more generic (for now its only source_dna)
    if(panel.restrictions[this.elLk.searchType.val()]) {
      $.each(panel.restrictions[this.elLk.searchType.val()], function(index, item) {
        panel.sourceRemoved.push(panel.elLk.form.find("[name=source_dna] option[value='"+item.value+"']").replaceWith(''));
      });
    } else {
      //restore to original dropdown if there was any filtering applied before
      if(panel.sourceRemoved.length) {
        $.each(panel.sourceRemoved, function(index, el){
          panel.elLk.form.find("[name=source_dna]").append(el);
        });
        panel.sourceRemoved = [];
      }
    }
  },

  resetSourceTypes: function(selectedSpecies) {
  /*
   * Resets the source type dropdown to disable the source options that are not available for one of the selected species
   */
    var sourcesToDisable = [];
    for (var i = selectedSpecies.length - 1; i >= 0; i--) {
      sourcesToDisable = sourcesToDisable.concat(this.missingSources[selectedSpecies[i]] || []);
    }

    this.elLk.source.find('option').prop('disabled', function() { return sourcesToDisable.indexOf(this.value) >= 0; }).end().each(function() {
      var opts = $(this).find('option:enabled');
      if (!opts.filter(':selected').length) {
        opts.first().prop('selected', true);
      }
      opts = null;
    });
  },

  updateSeqInfo: function(info) {
  /*
   * Updates the text content below the sequence
   */
    var panel = this;

    if (info) {
      if (info.is_rna === true && this.rnaMessageDisplayed === false) {
        var rnaSequenceMessage = '<div class="rna_seq_message bottom-margin">You have added a RNA sequence. However, it has been replaced by its DNA equivalent.</div>';

        $('[name=query_type]:first').parent().before(rnaSequenceMessage);
        this.rnaMessageDisplayed = true;
      }
    } else {
      $('.rna_seq_message').remove();
      this.rnaMessageDisplayed = false;
    }

    if (!this.elLk.sequenceInfo) {
      this.elLk.sequenceInfo = $('<div class="italic">').appendTo(this.elLk.sequences).on('click', 'a', function(e) {
        e.preventDefault();
        panel.elLk.sequenceInfo.hide();
        panel.toggleSequenceFields(true);
      });
    }
    var message = ($.type(info) === 'object'
      ? (parseInt(info.added) || 'No')
        + (this.sequences.length - info.added ? ' more' : '')
        + ' sequence'
        + (info.added > 1 ? 's' : '')
        + ' added'
        + (info.invalids ? ' (' + info.invalids + ' invalid or duplicate sequence' + (info.invalids > 1 ? 's' : '') + ' ignored)' : '')
        + ', '
      : ''
    );
    this.elLk.sequenceInfo.toggle(!!info).html((this.maxNumSequences === this.sequences.length ? '' : '<a href="#">Add more sequences</a> ')
      + '(' + message
      + ((this.maxNumSequences - this.sequences.length) || (message ? 'no' : 'No'))
      + (this.sequences.length ? ' more' : '')
      + ' sequence'
      + (this.maxNumSequences - this.sequences.length > 1 ? 's' : '')
      + ' allowed)'
    );
  },

  resetSpecies: function(list) {
  /*
   * Resets the checkboxes to select only those species that are given in speciesList
   */
    var items = $.map(list, function(item, i) {
      return {
        key: item,
        title: item
      };
    });

    Ensembl.EventManager.deferTrigger('updateTaxonSelection', items);
  },

  setSensitivityConfigs: function(el) {
  /*
   * Sets the configurations according to current value of the sensitivity dropdown
   * @param The relevant sensitivity dropdown object, or the type of blast currently selected
   */
    var panel = this;
    if (typeof el === 'string') {
      el = this.elLk.sensitivityOptions.filter('[name$=' + el + ']').first();
    }
    if (!el.length) {
      return;
    }
    var btype   = el.prop('name').replace('config_set_','');
    var ctype   = el.find('option:selected').val();
    var config  = false;
    if (btype in this.sensitivityConfigs) {
      if (ctype in this.sensitivityConfigs[btype]) {
        config = this.sensitivityConfigs[btype][ctype];
      }
    }
    if (config && !$.isEmptyObject(config)) {
      $.each(config, function(name, value) {
        panel.elLk.form.find('[name=' + btype + '__' + name + ']').filter('input').prop('checked', !!value).end().filter('select').find('option[value="' + value + '"]').prop('selected', true).end().selectToToggle('trigger');
      });
    }
    btype = ctype = config = null;
  }
});

Ensembl.Class.BlastFormSequence = Ensembl.Class.ToolsFormSubElement.extend({
/*
 *  This represents a sequence box in the frontend
 */

  constructor: function(seq, parent, previous) {
  /* Creates an HTML structure for the element with required events
   */
    this.base();

    var self    = this;
    this.parent = parent;

    this.elLk.input = $('<input>', {'type' : 'hidden', 'name': 'sequence', 'value': ''}); // hidden input containing the sequence value
    this.elLk.close = parent.elLk.sequenceInputClose.clone().helptip({content: 'Remove sequence'}).show().on('click', function() { self.parent.removeSequence(self); });

    // actual editable sequence box
    this.elLk.seqBox = $('<div>', {'class': 'fasta-input'}).on({
      'click': function(e) {
        $(this).filter(':not(.editable)').addClass('editable').prop({'contentEditable': true, 'spellcheck': false}).focus().data('prevSequence', $(this).text());
      },
      'blur keyup': function(e) {
        if (e.type === 'blur' || e.type === 'keyup' && e.which === 27) {
          var seqBox = $(this).filter('.editable').removeClass('editable').prop('contentEditable', false).find('br').replaceWith('\n').end().end();
          if (e.type === 'keyup') { // escape key
            seqBox.text(seqBox.data('prevSequence'));
          } else if (seqBox.data('prevSequence') != seqBox.text()) {
            self.parent.modifySequence(self, seqBox.text());
          }
        }
      },
      'keypress': function(e) {
        if (e.which === 13) {
          if (window.getSelection) {
            e.preventDefault();
            var selection = window.getSelection();
            var range     = selection.getRangeAt(0);
            var br        = document.createElement('br');
            range.deleteContents();
            range.insertNode(br);
            range.setStartAfter(br);
            range.setEndAfter(br);
            range.collapse(false);
            selection.removeAllRanges();
            selection.addRange(range);
          }
        }
      }
     });

    // wrapping div
    this.elLk.div = $('<div>', {'class': 'seq-wrapper'}).append(this.elLk.input, this.elLk.seqBox, this.elLk.close).appendTo(parent.elLk.sequences.show()).insertBefore(previous && previous.elLk.div.next() || parent.elLk.sequenceInfo).end();

    this.init(seq);
  },

  init: function(seq) {
  /* Initialises the object with the given sequence data (this can be called on an already initialised object to reinitialise it with different sequence data)
   */
    this.string       = seq.string;
    this.type         = seq.type;
    this.description  = seq.description;
    this.guessedType  = seq.type;

    var seqString     = this.description + '\n' + this.string.match(/(.{1,60})/g).join('\n'); // split strings into 60 char each (fasta format)

    this.elLk.input.val(seqString);
    this.elLk.seqBox.text(seqString);
  }
});

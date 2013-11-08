Ensembl.Panel.BlastForm = Ensembl.Panel.ToolsForm.extend({
  constructor: function () {
    this.base.apply(this, arguments);

    Ensembl.EventManager.register('editToolsTicket', this, this.loadTicket);

    this.sequences            = [];
    this.combinations         = [];
    this.fieldsOrder          = {};
    this.fieldTags            = {};
    this.speciesTags          = {};
    this.dropdowns            = {};
    this.selectedValues       = {};
    this.maxSequenceLength    = 0;
    this.maxNumSequences      = 0;
    this.dnaThresholdPercent  = 0;
    this.loadTicketURL        = '';
  },

  init: function () {

    this.base();
    var panel                 = this;

    this.maxSequenceLength    = this.elLk.form.find('input[name=max_sequence_length]').remove().val();
    this.maxNumSequences      = this.elLk.form.find('input[name=max_number_sequences]').remove().val();
    this.dnaThresholdPercent  = this.elLk.form.find('input[name=dna_threshold_percent]').remove().val();
    this.loadTicketURL        = this.elLk.form.find('input[name=load_ticket_url]').remove().val();
    this.readFileURL          = this.elLk.form.find('input[name=read_file_url]').remove().val();

    try {
      // parse the combination JSON from the HTML - if this doesn't work, there is nothing we can do!
      this.combinations       = $.parseJSON(this.elLk.form.find('input[name=valid_combinations]').remove().val());

      // get the fields order from the order they appear on the form
      this.elLk.form.find($.map(this.combinations[0], function(val, key) {
        return '[name=' + key + ']';
      }).toString()).each(function(key, el) {
        if (!(el.name in panel.fieldsOrder)) {
          panel.fieldsOrder[el.name] = 1;
        }
      });

      // sort the combinations according to the field's order
      this.sortCombinations();

    } catch (ex) {
      this.combinations       = false;
    }

    // nothing can be done if any of these is missing!
    if (!this.combinations || !this.maxSequenceLength || !this.dnaThresholdPercent || !this.maxNumSequences) {
      this.showError('JavaScript error occurred while initiating the Blast form.', 'Blast form error');
      return;
    }

    this.elLk.sequences       = this.elLk.form.find('div._sequence').first().removeClass('_sequence');
    this.elLk.sequenceFields  = this.elLk.form.find('div._sequence');
    this.elLk.speciesDropdown = this.elLk.form.find('div._species_dropdown');
    this.elLk.adjustableDivs  = this.elLk.form.find('div._adjustable_height').css('minHeight', function() { return $(this).height(); });
    this.elLk.configFields    = this.elLk.form.find('div._config_field');

    // 'Add more sequences' link
    this.elLk.addSeqLink      = this.elLk.sequences.find('._add_sequence').on('click', function(e) {
      e.preventDefault();
      panel.toggleSequenceFields(true);
    });

    // Query type radio button
    this.elLk.queryType       = this.elLk.form.find('input[name=query_type]').on('change', function() {
      panel.setQueryTypeValue(this.value);
    });

    // species tags
    this.elLk.speciesTags     = this.elLk.form.find('._species_tags').find('div').each(function() {
      panel.speciesTags[$(this).find('input').val()] = new Ensembl.Panel.ToolsForm.SpeciesTag($(this), panel);
    }).end();

    // 'Add species' link
    this.elLk.addSpeciesLink  = this.elLk.form.find('._add_species').find('a').on('click', function(e) {
      e.preventDefault();
      panel.toggleSpeciesFields(true);
    }).end();

    // 'Done' link - done adding species
    this.elLk.doneSpeciesLink = this.elLk.form.find('._add_species_done').find('a').on('click', function(e) {
      e.preventDefault();
      panel.refreshSpecies();
      panel.toggleSpeciesFields(false);
    }).end();

    // for all the fields that affect the selectable options in other fields, provide the event handlers; and initialise the Dropdown instances
    this.elLk.form.find('._validate_onchange').on('change', function() {
      panel.fieldTags[this.name].select(this.nodeName == 'INPUT' ? $(this) : $(this).find('option:selected'));
    }).filter('select').each(function() {
      panel.dropdowns[this.name] = new Ensembl.Panel.ToolsForm.Dropdown($(this), panel);
    });

    // provide event handlers to the textarea where sequence text is typed
    this.elLk.sequenceInput   =  this.elLk.form.find('textarea[name=query_sequence]').on({
      'focus': function(e) {
        if (!this.value || this.value == this.defaultValue) {
          $(this).val('').removeClass('inactive');
        }
      },
      'blur change.noinput': function() {
        if (!this.value || this.value == this.defaultValue) {
          $(this).addClass('inactive').val(this.defaultValue).trigger('showButtons', false);
        }
      },

      'input cut.noinput paste.noinput keyup.noinput': function(e) {
        if (e.type == 'input') {
          $(this).off('.noinput'); // we only need these extra events if input event is not supported
        }
        $(this).trigger('showButtons', e.type != 'input' || !!this.value);
      },
      'showButtons': function(e, flag) {
        var textarea = $(this).toggleClass('shadow', flag);
        var buttons = textarea.data('buttons');
        if (!buttons) {
          buttons = $('<div class="fasta-buttons"><span>Done</span><span>Clear</span></div>').appendTo($(this).parent()).on('click', 'span', function() {
            if (this.innerHTML == 'Done') {
              textarea.each(function() {
                if (this.value && this.value != this.defaultValue) {
                  panel.addSequences(this.value);
                }
              }).trigger('showButtons', false);
            } else {
              textarea.val('').trigger('focus').trigger('showButtons', false);
            }
          });
          textarea.data('buttons', buttons);
        }
        buttons.toggle(flag);
      }
    });

    // if any file is added to the file field, read it and display the sequence
    this.elLk.queryFile = this.elLk.form.find('input[name=query_file]').on('change', function() {
      if (window.FileList && window.File && window.FileReader) {
        if (!panel.fileReader) { // to avoid multiple instances
          panel.fileReader = new FileReader();
        }
        panel.fileReader.onload = function(readerEvent) {
          var seqText = readerEvent.target.result;
          panel.addSequences(seqText);
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
        panel.toggleSpinner(true);
        panel.ajax({
          'url'     : panel.readFileURL,
          'iframe'  : true,
          'form'    : panel.elLk.form,
          'success' : function(json) {
            if ('file_error' in json) {
              this.showError(json['file_error']);
            } else if ('file' in json) {
              this.addSequences(json['file']);
            }
          },
          'complete': function() {
            panel.toggleSpinner(false);
            panel.elLk.queryFile.val('');
          }
        });
      }
    });

    // Retrieve the sequence if accession id etc is provided
    this.elLk.form.find('input[name=retrieve_accession]').on('change', function() {
        // TODO - accession ID
    });

    // initialise the FieldTag instances
    this.elLk.form.find('select, input').each(function() {
      var tagDiv = panel.elLk.form.find('._tag_' + this.name);
      if (tagDiv.length) {
        if (!panel.fieldTags[this.name]) {
          panel.fieldTags[this.name] = new Ensembl.Panel.BlastForm.FieldTag(tagDiv, panel);
        }
        panel.fieldTags[this.name].addField($(this));
      }
    });

    // add child tags to the FieldTags (eg. source is child tag of db_type - if db_type tag is removed, source gets removed too)
    for (var fieldName in this.fieldTags) {
      this.fieldTags[fieldName].setChildTags(this.fieldTags);
    }
    fieldName = null;

    // Fill in the form if editing an existing job
    var editingJobsData       = [];
    try {
      editingJobsData         = $.parseJSON(this.elLk.form.find('input[name=edit_jobs]').remove().val());
    } catch (ex) {}
    if (editingJobsData.length) {
      this.populateForm(editingJobsData);
    }

    this.refreshSpecies();
  },

  reset: function() {
  /*
   * Resets the form, ready to accept next job input
   */
   
    this.base();

    // Reset sequences
    for (var i in this.sequences) {
      this.sequences[i].destructor();
    }
    this.sequences = [];
    this.updateSeqInfo(false);
    this.toggleSequenceFields(true, false);

    // Reset species
    this.refreshSpecies([]);

    // Reset query_type, db_type, source and search_type
    for (var i in this.fieldTags) {
      this.fieldTags[i].select(false, true); // second argument prevents calling updateSelections, which is a slow method and is done once all tags are deselected.
    }
    this.updateSelections('');

    // Set focus on the sequence textarea
    this.elLk.sequenceInput.trigger('focus');    
  },

  loadTicket: function(ticketName) {
    this.ajax({'url':  this.loadTicketURL.replace('TICKET_NAME', ticketName)});
    return true;
  },

  populateForm: function(jobsData) {

    this.reset();
    
    var formInput = {};
    if (jobsData.length) {
      for (var i in jobsData) {
        for (var paramName in jobsData[i]) {
          if (paramName == 'sequence' || paramName == 'species') {
            if (!(paramName in formInput)) {
              formInput[paramName] = [];
            }
            formInput[paramName].push(jobsData[i][paramName]);
          } else {
            formInput[paramName] = jobsData[i][paramName];
          }
        }
      }
    }

    if (!$.isEmptyObject(formInput)) {
      this.addEditingJobSequences(formInput['sequence'], formInput['query_type']);
      this.refreshSpecies(formInput.species);
      for (var i in this.fieldTags) {
        this.fieldTags[i].select(formInput[i]);
      }
      for (var name in formInput['configs']) {
        this.elLk.form.find('[name=' + formInput['search_type'] + '__' + name + ']')
          .filter('input[type=checkbox]').prop('checked', true).end()
          .filter('select').find('option[value=' + formInput['configs'][name] + ']').prop('selected', true);
      }
    }
  },

  sortCombinations: function() {
    var panel = this;
    this.combinations = $.map(this.combinations, function(combination) {
      var sortedCombination = {};
      for (var i in panel.fieldsOrder) {
        sortedCombination[i] = combination[i];
      }
      return sortedCombination;
    });
  },

  getQueryTypeValue: function() {
    return this.elLk.queryType.filter(':checked').val();
  },

  setQueryTypeValue: function(queryType) {
    var selectedQueryType;

    if (!queryType) {

      // if a query type has already been selected by the user, that can not be changed!
      selectedQueryType = this.selectedValues[this.elLk.queryType.attr('name')];

      // if no query type is selected, but there is only one enabled input, there's no option other than to select it
      if (!selectedQueryType && this.elLk.queryType.filter(':enabled').length === 1) {
        selectedQueryType = this.elLk.queryType.filter(':enabled').val();
      }

      // if both options can be selected, check which query type has more number of sequences
      if (!selectedQueryType) {
        var queryTypes = {'peptide': 0, 'dna': 0};
        $.each(this.sequences, function() {
          queryTypes[this.type]++;
        });

        // give preference to already selected one if both are equal
        if (queryTypes.peptide == queryTypes.dna) {
          queryType = this.getQueryTypeValue();
        } else {
          queryType = queryTypes.peptide < queryTypes.dna ? 'dna' : 'peptide';
        }
      }
    }

    // update the other selections accordingly, but only when new query_type selection is made
    if (!selectedQueryType) {
      this.fieldTags[this.elLk.queryType.attr('name')].select(queryType);
    }

    // select only those sequences which fall under the current selected queryType
    this.selectSequences(selectedQueryType || queryType);
  },

  selectSequences: function(queryType) {
    $.each(this.sequences, function() {
      this.resetCheckbox(queryType);
    });
  },

  addSequences: function(rawText, existingSequence) {

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
        if (parsedSeqs.sequences[indexParsedSeq].string == this.sequences[indexSeq].string && !(existingSequence && this.sequences[indexSeq] == existingSequence)) {
          duplicates++;
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
        this.sequences.splice(existingSequence && this.sequences.indexOf(existingSequence) + 1 || numSeqs, 0, new Ensembl.Panel.BlastForm.Sequence(parsedSeqs.sequences[indexParsedSeq], this, existingSequence || false));
      }
      numSeqs = this.sequences.length;
    }

    if (numSeqs) {
      this.setQueryTypeValue(); // let it decide the query type itself
      this.toggleSequenceFields(false, true);
      this.adjustDivsHeight();
    }

    this.updateSeqInfo({'added': indexParsedSeq - duplicates, 'invalids': parsedSeqs.invalids + duplicates});

    parsedSeqs = duplicates = modifyingExisting = numParsedSeqs = numSeqs = indexSeq = null;

    return indexParsedSeq;
  },

  parseRawSequences: function(rawText) {
  /* Parses raw text into fasta sequences, possibly multiple fasta sequences
   * @return Object with following keys
   *  sequences: Array of objects each containing three keys: type, description and string
   *  duplicates: number of duplicates ignored
   */
    var bases           = 'ACTGNX';
    var inputSeqs       = rawText.replace(/^[\s\n\t]+|[\s\n\t]+$/g, '').split(/(?=>)|\n+[\s\t]*\n+/); // '>' or an empty line represents start of a new sequence
    var sequences       = [];

    var sequenceLines, pointer, seqLine, seqChar, seqDNACharCount, i, j;

    rawSeqLoop:
    for (i in inputSeqs) {
      sequenceLines   = inputSeqs[i].split(/[\s\t]*\n[\s\t]*/);
      pointer         = 0;
      seqDNACharCount = 0;
      seqString       = '';
      sequence        = {'string': '', 'description': '>', 'type': ''};

      seqLineLoop:
      for (j in sequenceLines) {
        seqLine = sequenceLines[j];
        pointer = 0;
        if (seqLine.match(/^(>|\;)/)) {
          if (j == 0) { // it's description if it's the first line, otherwise ignore, as it's a comment
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

      sequence.type   = 100 * seqDNACharCount / sequence.string.length < this.dnaThresholdPercent ? 'peptide' : 'dna';

      // skip if it's a duplicate, or invalid sequence
      for (j in sequences) {
        if (sequences[j].string == sequence.string) {
          continue rawSeqLoop;
        }
      }

      // invalid sequence
      if (!sequence.string.match(/^[A-Z\*]+$/)) {
        continue rawSeqLoop;
      }

      sequences.push(sequence);

      if (sequences.length >= this.maxNumSequences) { // already added sequences are not considered in this count as there might be some duplicates that get removed later on.
        break rawSeqLoop;
      }
    }
    return {'sequences': sequences, 'invalids': 1 + parseInt(i) - sequences.length};
  },

  addEditingJobSequences: function(editingJobSequences, type) {
  /* Adds the sequences from the data received from the backend for a job that needs to be edited
   */
    seqLoop:
    for (var i in editingJobSequences) {
      for (var j in this.sequences) {
        if (editingJobSequences[i].seq == this.sequences[j].string) {
          continue seqLoop;
        }
      }
      if (this.sequences.length >= this.maxNumSequences) {
        break;
      }
      this.sequences.push(new Ensembl.Panel.BlastForm.Sequence({
        'string'      : editingJobSequences[i].seq,
        'description' : '>' + (editingJobSequences[i]['display_id'] || ''),
        'type'        : type
      }, this, false));
    }

    if (this.sequences.length) {
      this.setQueryTypeValue(type);
      this.toggleSequenceFields(false, true);
      this.adjustDivsHeight();
    }

    this.updateSeqInfo({'added': this.sequences.length});

    return this.sequences.length;
  },

  modifySequence: function(sequenceObject, rawText) {
    if (rawText && !!this.addSequences(rawText, sequenceObject)) { // if sequence was valid and is successfully modified
      this.updateSeqInfo(true);
      return;
    }

    // remove the sequence otherwise
    this.sequences.splice(this.sequences.indexOf(sequenceObject), 1);
    sequenceObject.destructor();
    sequenceObject = null;

    var flag = !!this.sequences.length;
    this.toggleSequenceFields(!flag, flag);
    this.updateSeqInfo(flag);
    this.adjustDivsHeight();
  },

  toggleSequenceFields: function(flag1, flag2) {
    if ($.type(flag2) === 'boolean') {
      this.elLk.sequences.toggle(flag2);
    }
    this.elLk.addSeqLink.toggle(!flag1 && this.sequences.length < this.maxNumSequences);
    this.elLk.sequenceFields.toggle(flag1).find('input, textarea').val('').first().focus();
  },

  updateSeqInfo: function(info) {
    if (!this.elLk.seuqenceInfo) {
      this.elLk.seuqenceInfo = this.elLk.sequences.clone().empty().insertAfter(this.elLk.sequences).addClass('italic').show();
    }
    var message = ($.type(info) == 'object'
      ? (parseInt(info.added) || 'No')
        + (this.sequences.length - info.added ? ' more' : '')
        + ' sequence'
        + (info.added > 1 ? 's' : '')
        + ' added'
        + (info.invalids ? ' (' + info.invalids + ' invalid or duplicate sequence' + (info.invalids > 1 ? 's' : '') + ' ignored)' : '')
        + ', '
      : ''
    );
    this.elLk.seuqenceInfo.toggle(!!info).html( message
      + ((this.maxNumSequences - this.sequences.length) || (message ? 'no' : 'No'))
      + (this.sequences.length ? ' more' : '')
      + ' sequence'
      + (this.maxNumSequences - this.sequences.length > 1 ? 's' : '')
      + ' allowed'
    );
  },

  toggleSpeciesFields: function(flag) {
    this.elLk.addSpeciesLink.toggle(!flag);
    this.elLk.speciesDropdown.toggle(flag);
    this.elLk.speciesTags.toggle(!flag);
    this.elLk.doneSpeciesLink.toggle(flag);
    if (flag) {
      this.elLk.speciesDropdown.find('._fd').filterableDropdown().find('input[type=text]').trigger('focus');
    }
  },

  refreshSpecies: function(species) {

    var speciesCheckboxes, existingTag, speciesName, selectedSpecies = {};

    if (species) {
      this.elLk.speciesDropdown.find('input').each(function() {
        if (species.indexOf(this.value) > -1) {
          this.checked = true;
        }
      });
    }

    speciesCheckboxes = this.elLk.speciesDropdown.find('input').filter(':checked').each(function() {
      return selectedSpecies[this.value] = $(this).parent().find('label').html();
    }).end();

    // if none selected, re-select the previously selected ones and ignore any changed
    if (!speciesCheckboxes.filter(':checked').length) {
      for (speciesName in this.speciesTags) {
        speciesCheckboxes.filter('[value="' + speciesName + '"]').prop('checked', true);
      }
      return;
    }

    // add new tags first (if we do if after removing the un-select tags, we may not get any tag to clone the new tags from)
    for (speciesName in this.speciesTags) {
      existingTag = this.speciesTags[speciesName];
      break;
    }
    for (speciesName in selectedSpecies) {
      if (!(speciesName in this.speciesTags)) {
        this.speciesTags[speciesName] = new Ensembl.Panel.ToolsForm.SpeciesTag(false, this, existingTag, {'value': speciesName, 'caption': selectedSpecies[speciesName]});
        
        //TODO - make an ajax request to refresh combinations
      }
    }

    // now remove the unselected ones
    for (speciesName in this.speciesTags) {
      if (!(speciesName in selectedSpecies)) {
        this.speciesTags[speciesName].remove();
        delete this.speciesTags[speciesName];
      }
    }

    for (speciesName in this.speciesTags) {
      this.speciesTags[speciesName].setRemovable(speciesCheckboxes.filter(':checked').length !== 1);
    }
  },

  updateSelections: function(targetFieldName) {

    var i,
        elements,
        fieldName,
        fieldValue,
        fieldTag,
        speciesNames,
        availableValues         = {},
        availableDefaultValues  = [],
        defaultFieldValues      = [],
        defaultValuesSelector   = []
    ;

    // filter out the mismatching ones
    FilteringLoop:
    for (i in this.combinations) {

      // skip if any of the fields is misatching
      for (fieldName in this.selectedValues) {
        if (this.combinations[i][fieldName] !== this.selectedValues[fieldName]) {
          continue FilteringLoop;
        }
      }

      // create a better accessible data structure for available values
      for (fieldName in this.combinations[i]) {
        if (!availableValues[fieldName]) {
          availableValues[fieldName] = [];
        }
        availableValues[fieldName][String(this.combinations[i][fieldName])] = 1;
      }

      // save the valid combinations for finding out the possible default options for the fields that have not been selected by the user yet
      availableDefaultValues.push(this.combinations[i]);
    }

    // select/deselect fields accordingly, and show/hide the FieldTags as required
    for (fieldName in availableValues) {
      if (fieldName == 'species') {
        for (speciesNames in availableValues[fieldName]) {
          // TODO - update the species list - disable the species that don't have this db
          // console.log(speciesNames);
        }
      } else {
        fieldTag  = this.fieldTags[fieldName];
        dropdown  = this.dropdowns[fieldName];

        // unhide all the hidden options first
        if (dropdown) {
          dropdown.reset();
        }

        // enabled/disable options according to their availability
        elements = this.elLk.form.find('select[name=' + fieldName + '] option, input[name=' + fieldName + ']').prop('disabled', function() {
          return !(this.value in availableValues[fieldName]);
        });

        // change all the fields other than the targeted field
        if (targetFieldName != fieldName) {

          // TODO - get the actual default values from the backend (eg. if db_type = DNA, source should default to 'Genomic sequence')
          // all the values that this field can default to if not selected by the user, and create a selector to select fields that those values only
          defaultFieldValues    = $.map(availableDefaultValues, function(defaultValues) { return defaultValues[fieldName]; });
          defaultValuesSelector = $.map(defaultFieldValues, function(defaultValue) { return '[value="' + defaultValue + '"]'; }).toString();

          if (elements.prop('nodeName') == 'OPTION') {

            // if selected option is not enabled and not found in list of available default values, select the first enabled option from the available default options list
            if (defaultFieldValues.indexOf(elements.parents('select').find('option:selected:enabled').val()) < 0) {
              elements.filter(defaultValuesSelector).first().prop('selected', true);
            }

            // if the value isn't selected, show readonly tag if only one option is available
            if (!(fieldName in this.selectedValues)) {
              fieldTag.setReadonly(elements.filter(':enabled').length == 1);
            }

          // for input tag, select the first available option if none selected
          } else {
            if (defaultFieldValues.indexOf(elements.filter(':checked:enabled').val()) < 0) {
              elements.filter(defaultValuesSelector).first().prop('checked', true);
            }
          }

          fieldValue = elements.filter(':selected, :checked').val();

          // filter the availableDefaultValues according to the selected values
          availableDefaultValues = $.grep(availableDefaultValues, function(combination) {
            return combination[fieldName] === fieldValue;
          });

          // now if the current selection changed the queryType (triggered by some other field change), we need to update the selected sequences
/*
          if (fieldName == this.elLk.queryType.attr('name')) {
            this.selectSequences(fieldValue);
          }
*/
        }

        // hide the disabled options, and trigger selecttotoggle event
        if (dropdown) {
          dropdown.removeDisabledOptions();
          dropdown.triggerSelectToToggle();
        }
      }
    }

    i = elements = fieldName = fieldValue = fieldTag = speciesNames = availableValues = availableDefaultValues = defaultFieldValues = defaultValuesSelector = null;
  }
});

Ensembl.Panel.BlastForm.Sequence = Ensembl.Panel.ToolsForm.SubElement.extend({
/*
 *  This represents a sequence box in the frontend
 */

  constructor: function(seq, parent, previous) {
  /* Creates an HTML structure for the element with required events
   */
    this.base();

    var self    = this;
    this.parent = parent;

    // tag on the rhs
    this.elLk.queryTypeTag = $('<div>', {'class': 'seq-type'});

    // checkbox on the lhs
    this.elLk.checkbox = $('<input>', {'type' : 'checkbox', 'name': 'sequence', 'checked': true, 'value': ''}).on('change', function(e) {
      $(this).data('userChecked', this.checked);
      if (this.checked) {
        self.type = self.parent.getQueryTypeValue();
        self.resetQueryTypeTag();
      }
      self.checkboxChanged(e);
    });

    // actual editable sequence box
    this.elLk.seqBox = $('<div>', {'class': 'fasta-input'}).on({
      'click': function(e) {
        $(this).filter(':not(.editable)').addClass('editable').prop({'contentEditable': true, 'spellcheck': false}).focus().data('prevSequence', $(this).text());
      },
      'blur keyup': function(e) {
        if (e.type == 'blur' || e.type == 'keyup' && e.which == 27) {
          var seqBox = $(this).filter('.editable').removeClass('editable').prop('contentEditable', false).find('br').replaceWith('\n').end().end();
          if (e.type == 'keyup') { // escape key
            seqBox.text(seqBox.data('prevSequence'));
          } else if (seqBox.data('prevSequence') != seqBox.text()) {
            self.parent.modifySequence(self, seqBox.text());
          }
        }
      }
    });

    // wrapping div
    this.elLk.div = $('<div>', {'class': 'seq-wrapper'}).append($('<div>').append(this.elLk.checkbox), this.elLk.seqBox, this.elLk.queryTypeTag).insertBefore(previous && previous.elLk.div.next() || parent.elLk.addSeqLink.parent());

    this.init(seq);
  },

  init: function(seq) {
  /* Initialises the object with the given sequence data (this can be called on an already initialised object to reinitialise it with different sequence data)
   */
    this.string       = seq.string;
    this.type         = seq.type;
    this.description  = seq.description;
    this.guessedType  = seq.type;

    var seqString     = this.description + '\n' + this.string.match(/(.{1,60})/g).join('\n'); // split strings into 60 char each (fast format)

    this.elLk.checkbox.val(seqString);
    this.elLk.seqBox.text(seqString);

    this.resetQueryTypeTag();
  },

  checkboxChanged: function(e) {
  /* Greys out the sequence text when checkbox is unselected and vice-versa
   */
    this.elLk.div.toggleClass('inactive', !this.elLk.checkbox[0].checked);
  },

  resetCheckbox: function(queryType) {
  /* Resets the checkbox according to the given querytype
   */

    // Do not change it if it's been changed by user, just change the type to fit the current selection
    if (typeof this.elLk.checkbox.data('userChecked') !== 'undefined') {
      if (this.elLk.checkbox.data('userChecked')) {
        this.type = queryType;
        this.resetQueryTypeTag();
      }
      return;
    }

    // if it's checked but query types don't match, or if it's not checked but the query types match
    if (this.elLk.checkbox.is(':checked') != (queryType == this.type)) {
      this.elLk.checkbox.prop('checked', queryType == this.type);
      this.checkboxChanged();
    }
  },

  resetQueryTypeTag: function() {
  /* Resets the query type tag on the right hand side according to the guessed type for the sequence and the type forced by the user
   */
    this.elLk.queryTypeTag.html(this.type == this.guessedType ? this.guessedType :  '<span>' + this.guessedType + '</span>' + this.type);// TODO - the tooltip is jumpy due to nested span
    if (this.type == this.guessedType) {
      this.elLk.queryTypeTag.helptip({}).helptip('destroy');
    } else {
      this.elLk.queryTypeTag.helptip({'content' : 'This seems to be a ' + this.guessedType + ' sequence, but will be considered as a ' + this.type + ' sequence'});
    }
  }
});

Ensembl.Panel.BlastForm.FieldTag = Ensembl.Panel.ToolsForm.SubElement.extend({
/*
 *  This class represents the Tags with an edit icon on the right
 *  The purpose of this element in the interface is to get hold of an event when user wants to unselect something.
 *  When an input field is selected by a user, this tag is disaplayed (and field is hidden), forcing other field's options to be adjusted according to this field's selection
 *  When this tag is removed, it's field still shows the same selected option, but other fields now can be changed by the user without considering this field's selected value
 */
  constructor: function(div, panel) {
    var self        = this;
    this.panel      = panel;
    this.div        = div.on('click', function() { self.readOnly || self.select(false); });
    this.parentDivs = this.div.parents('div:not(:visible)');
    this.selected   = false; // flag telling whether selected by user or not
    this.field      = $();
    this.childTags  = [];
    this.type       = '';
    this.name       = '';
    this.readOnly   = false;
  },

  addField: function(field) {
    this.field  = this.field.add(field);
    this.type   = this.field.prop('nodeName');
    this.name   = this.field.attr('name');
  },

  select: function(target, noUpdate) {
    if (target === false) {
      if (!this.selected) { // already not selected
        return;
      }
      for (var i in this.childTags) {
        this.childTags[i].select(false, true);
      }
      delete this.panel.selectedValues[this.name];
      if (!noUpdate) {
        this.panel.updateSelections(this.name);
      }
    } else {
      if (!(target instanceof $)) {
        target = this.type == 'INPUT' ? this.field.filter('[value=' + target + ']').prop('checked', true) : this.field.find('option[value=' + target + ']').prop('selected', true);
      }
      this.panel.selectedValues[this.name] = target.val();
      if (!noUpdate) {
        this.panel.updateSelections(this.name);
      }
    }
    this.toggle(this.selected = !!target);
  },

  setChildTags: function(allTags) {
    var match, className = this.div.prop('className'), rexExp = /_tag_child_([^\s]+)/g;
    while (match = rexExp.exec(className)) {
      if (allTags[match[1]]) {
        this.childTags.push(allTags[match[1]]);
      }
    }
  },

  setReadonly: function(readOnly) {
    this.toggle(readOnly);
    this.div.toggleClass('readonly', readOnly);
    this.readOnly = readOnly;
  },

  toggle: function(flag) {
    this.parentDivs.toggle(flag);
    this.field.parents('div').first().toggle(!flag);
    if (flag) {
      this.div.children(':first-child').html(this.type == 'INPUT' ? this.field.filter(':checked').parent().find('label').html() : this.field.find('option:selected').html());
    }
    this.panel.adjustDivsHeight();
  }
});

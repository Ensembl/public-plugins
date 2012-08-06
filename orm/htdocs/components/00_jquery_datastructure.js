/**
 * datastructure
 * jQuery plugin to make a user friendly editor for perl hash datastructures
 * TODO - needs optimisation
 * TODO - change divs to span with display:block to prevent divs going inside inline elements
 */

(function($) {

  $.datastructure = function (el) {

    el = $(el);
    
    var isReadonly = !el[0].nodeName.match(/^(TEXTAREA|INPUT)$/);

    // private method to parse the string to a datastructure
    var parse = function(str) {
      try {
        return eval('(' + str.replace(/\=>/gm, ':') + ')');
      }
      catch (e) {
        throw 'Invalid data structure. Please change the source.';
      }
    };

    // private sorting method to ignore cases
    var ignoreCases = function(a, b) {
      a = a.toLowerCase();
      b = b.toLowerCase();
      return a > b && 1 || a < b && -1 || 0;
    };

    // private method for encoding strings for class attribute
    var encodeClassName = function(str) {
      return encodeURIComponent(str).replace('_', '%5F').replace(/%/g, '_');
    };

    // private method to close all popup menus
    var closeMenu = function() {
      $('#_ds_menu, #_ds_key_menu').hide();
    };

    // Tabs class
    var DSTabs = function(buttons, tabs, active) {
      buttons.each(function(i) {
        $(this).click(function(event) {
          event.preventDefault();
          $(tabs.hide()[i]).show();
          $(buttons.removeClass('selected')[i]).addClass('selected');
        });
      });
      buttons.first().trigger('click');
    };

    // Menu object
    var DSMenu = {
      construct: function() {
        var self = this;
        if (this.el) {
          return;
        }
        if (document.getElementById('_ds_menu')) {
          this.el = $('#_ds_menu');
          return;
        }
        this.el = $('<div>')
          .attr({id: '_ds_menu', 'class': '-ds-menu'})
          .append($('<p>').attr({'class': '-ds-menu-close'})
            .append($('<a>').attr({href: '#close'}).html('Close').click(function(e) {
              e.preventDefault();
              closeMenu();
            }))
          )
          .append($('<p>').attr({id: '_ds_error', 'class': '-ds-error'}))
          .append($('<div id="_ds_menu_tab" class="-ds-tab">')
            .html('<a href="#hash"><span class="-ds-sel">Make </span>Hash</a><a href="#array"><span class="-ds-sel">Make </span>Array</a><a href="#string"><span class="-ds-sel">Make </span>String</a>')
          )
          .appendTo(document.body);

        var labels = {
          hash: 'Add key',
          array: 'Add element',
          string: 'String value'
        };

        $.each(labels, function(type, label) {
          self.el.append($('<div>').attr({'class': '-ds-tab-div'})
            .append($('<form class="_ds_form _ds_form_' + type + '">')
              .append($('<label>').html(label + ': '))
              .append($('<input>').attr({type: 'text'}).keypress(function(e) { if (e.keyCode === 27 || e.which === 27) { closeMenu(); } } ))
              .append('<input type="submit" value="Save">')
            )
          );
        });
        new DSTabs($('#_ds_menu_tab a', this.el), $('div.-ds-tab-div', this.el));
        $('#_ds_menu_tab a', this.el).bind('click', function() {
          var type = this.href.split('#').pop();
          setTimeout(function() {
            $('form._ds_form_' + type +' input[type=text]').focus().select();
          }, 100);
        });
      },

      init: function(dsEl, event) {
        var self = this;
        this.construct();
        closeMenu();
        this.dsEl = dsEl;
        $('#_ds_error').hide();
        $('#_ds_menu_tab a').filter('[href=#' + this.dsEl.type + ']').trigger('click');
        $('form._ds_form input[type=text]', this.el).val(this.dsEl.type === 'string' ? this.dsEl.value || '' : '');
        $('form._ds_form', this.el).unbind('submit').submit(function(event) {
          event.preventDefault();
          try {
            self.dsEl.modify((this.className.match(/_ds_form_([a-z]+)/) || []).pop(), $('input[type=text]', this).val());
          }
          catch(e) {
            $('#_ds_error').html(e).show();
            return;
          }
          closeMenu();
        });
        this.el.css({left: event.pageX + 'px', top: event.pageY + 'px'}).show();
      }
    };
    
    // Key renaming popup object
    var DSKeyMenu = {
      construct: function() {
        if (this.el) {
          return;
        }
        if (document.getElementById('_ds_key_menu')) {
          this.el = $('#_ds_key_menu');
          return;
        }
        this.el = $('<div>').attr({id: '_ds_key_menu', 'class': '-ds-menu'})
          .append('<p id="_ds_key_error" class="-ds-error">')
          .append($('<form>').append($('<input>').attr({type: 'text'}).bind({
            keypress: function(e) {
              if (e.keyCode === 27 || e.which === 27) {
                closeMenu();
              }
            },
            blur: function() {
              closeMenu();
            }
          })))
          .appendTo(document.body).hide();
      },
      init: function(dsEl, event, eventTarget) {
        var self = this;
        this.construct();
        closeMenu();
        this.dsEl = dsEl;
        this.span = eventTarget;
        $('#_ds_key_error').hide();
        $('input', this.el.css({left: event.pageX + 'px', top: event.pageY + 'px'}).show()).val(this.span.innerHTML).focus().select();
        $('form', this.el).bind({'submit': function(event) {
          event.preventDefault();
          var newKey = $('input', this).val();
          if (newKey) {
            try {
              self.dsEl.renameKey(self.span, newKey);
            }
            catch(e) {
              $('#_ds_key_error').html(e).show();
              return;
            }
          }
          closeMenu();
        }});
      }
    };

    // private class for each Element
    var DSElement = function(data, parent, ta, readOnly) {
    
      var self = this;
      var n = '<br />';
      var t = '  ';
      var p = '';
      
      this.ta     = ta;
      this.parent = parent;
      this.type   = 'hash';
      this.wrap   = $('<span>');
      this.el     = $('<span>').addClass('_ds_el').appendTo(this.wrap);
      this.value  = '';
      this.keys   = [];
      this.indent = 1;
      this.readOnly = readOnly || this.parent && this.parent.readOnly || false;

      // updates the text representation of hash in the textarea
      this.updateText = function() {
        this.parent ? this.parent.updateText() : this.ta.val(this.toString());
      };

      // adds a key to hash
      this.addKey = function(key, val, doModify) {
        var nextKey = false;
        if (doModify) {
          this.value[key] = val;
          this.keys.push(key);
          this.keys = this.keys.sort(ignoreCases);
          for (var i in this.keys) {
            if (this.keys[i] === key) {
              nextKey = this.keys[parseInt(i, 10) + 1];
              break;
            }
          }
          if (nextKey) {
            nextKey = $('>span._ds_key_' + encodeClassName(nextKey), this.el).first().prev();
          }
        }
        $.each([$('<span class="-ds-remove-button">').html(n + p + t), $('<span class="-ds-hil -ds-key _ds_key _ds_key_' + encodeClassName(key) + '">').html(key), $('<span>').html(' =&gt; '), val.display(this.indent + 1)], function() {
          nextKey ? nextKey.before(this) : self.el.append(this);
          if (doModify) {
            this.effect('highlight', {}, 2000);
          }
        });
        if (!this.readOnly) {
          $('>span._ds_key', this.el).bind({
            click: function(event) {
              self.getKeyMenu(event, this);
            }
          }).prev().bind({
            mouseover: function(event) {
              event.stopImmediatePropagation();
              $.each([this, this.nextSibling, this.nextSibling.nextSibling, this.nextSibling.nextSibling.nextSibling], function() { $(this).addClass('-ds-remove'); } );
            },
            mouseout: function() {
              $.each([this, this.nextSibling, this.nextSibling.nextSibling, this.nextSibling.nextSibling.nextSibling], function() { $(this).removeClass('-ds-remove'); } );
            }, 
            click: function(event) {
              event.stopImmediatePropagation();
              self.removeKey(this.nextSibling);
            }
          });
        }
      };

      // renames a hash key
      this.renameKey = function(span, newKey) {
        var oldKey = span.innerHTML;
        if (oldKey === newKey) {
          return;
        }
        this.checkKey(newKey);
        var k2 = [newKey];
        for (var i in this.keys) {
          if (this.keys[i] !== oldKey) {
            k2.push(this.keys[i]);
          }
        }
        this.keys = k2.sort(ignoreCases);
        this.value[newKey] = this.value[oldKey];
        delete this.value[oldKey];
        $(span).removeClass('_ds_key_' + encodeClassName(oldKey)).addClass('_ds_key_' + encodeClassName(newKey)).html(newKey).effect('highlight', {}, 1000);
        this.updateText();
      };

      // removes a hash key
      this.removeKey = function(span) {
        var key = span.innerHTML;
        if (!window.confirm("This will remove key '" + key + "' from the hash.")) {
          return;
        }
        var k2 = [];
        for (var i in this.keys) {
          if (this.keys[i] !== key) {
            k2.push(this.keys[i]);
          }
        }
        this.keys = k2.sort(ignoreCases);
        delete this.value[key];
        $.each([span.previousSibling, span.nextSibling.nextSibling, span.nextSibling, span], function() { $(this).remove(); });
        closeMenu();
        this.updateText();
      };

      // validates a key
      this.checkKey = function(key) {
        if ($.grep(this.keys, function(k) { return k === key; }).length) {
          throw 'Duplicate key';
        }
      };

      // removes a value from array
      this.removeArrVal = function(span) {
        var i = -1;
        var s = span;
        while (s = s.previousSibling) {
          i++;
        }
        i = Math.round(i/2);
        if (!window.confirm('This will remove the array element indexed at ' + i + '.')) {
          return;
        }
        this.value = this.value.splice(0, i).concat(this.value.splice(1));
        $.each([span.previousSibling, span], function() { $(this).remove(); });
        closeMenu();
        this.updateText();
      };

      // add element to array
      this.push = function(val, doModify) {
        if (doModify) {
          this.value.push(val);
        }
        var newEl = val.display(this.indent + 1);
        var newBt = $('<span class="-ds-remove-button">').html(n + p + t);
        if (!this.readOnly) {
          newBt.bind({
            mouseover: function(event) {
              event.stopImmediatePropagation();
              $.each([this, this.nextSibling], function() { $(this).addClass('-ds-remove'); } );
            },
            mouseout: function() {
              $.each([this, this.nextSibling], function() { $(this).removeClass('-ds-remove'); } );
            }, 
            click: function() {
              self.removeArrVal(this.nextSibling);
            }
          });
        }
        this.el.append(newBt, newEl);
        if (doModify) {
          newEl.effect('highlight', {}, 2000);
        }
      };

      // changes string value
      this.string = function(val, doModify) {
        var newStr = $('<span class="-ds-hil _ds_string">').html(val || '<i>undef</i>')
        if (!this.readOnly) {
          newStr.bind({ click: function(e) { self.getMenu(e); }});
        }
        if (doModify) {
          this.value = val;
          this.el.empty();
          newStr.effect('highlight', {}, 2000);
        }
        this.el.append(newStr);
      };
      
      //returns the final modified string equivalent of the element
      this.toString = function() {
        switch(this.type) {
          case 'string':
          return "'" + this.value + "'";

          case 'array':
          return '[' + $.map(this.value, function(v) { return v.toString(); }).join(',') + ']';

          case 'hash':
          var rtn = [];
          $.each(this.keys, function() { rtn.push("'" + this + "'=>" + self.value[this].toString()); });
          return '{' + rtn.join(',') + '}';
        }
      };

      // modifies the element with given value, and to given type
      this.modify = function(type, value) {
        if (type === 'hash') {
          this.checkKey(value);
        }
        if (this.type !== type) {
          if (this.type !== 'string') {
            for (var i in this.value) {
              this.value[i].destroy();
              delete this.value[i];
            }
          }
          this.keys = [];
          this.value = '';
          this.el.empty();
          this.removeBraces();
        }
        this.type = type;
        switch(this.type) {
          case 'string':
          if (value === this.value) {
            return;
          }
          this.string(value, true);
          break;

          case 'array':
          if (!this.value) {
            this.addBraces('[]');
            this.value = [];
          }
          if (value) {
            this.push(new DSElement(value, this), true);
          }
          break;

          case 'hash':
          if (!this.value) {
            this.addBraces('{}');
            this.value = {};
          }
          if (value) {
            this.addKey(value, new DSElement('', this), true);
          }
          break;
        }
        this.updateText();
      };

      // shows the popup to modify the element
      this.getMenu = function(event) {
        DSMenu.init(this, event);
      };

      // shows the popup to rename a key
      this.getKeyMenu = function(event, eventTarget) {
        DSKeyMenu.init(this, event, eventTarget);
      };

      // removes the braces from around an element eg. [] for an array, {} for a hash
      this.removeBraces = function() {
        $('span._ds_brace', this.wrap).remove();
      };

      // adds wraping braces for an array or a hash
      this.addBraces = function(braces) {
        var closingBrace = $('<span class="-ds-hil _ds_brace">').html(n + p + braces.charAt(1));
        if (!this.readOnly) {
          closingBrace.bind({
            click: function(e) {
              self.getMenu(e);
            }
          });
        }
        this.wrap.prepend($('<span class="_ds_brace">').html(braces.charAt(0))).append(closingBrace);
      };

      // method to display element data
      this.display = function(indent) {
        this.indent = indent || 1;
        for (var i = 0; i < this.indent - 1; i++) {
          p += '  ';
        }

        switch(this.type) {
          case 'string':
          this.string(this.value);
          break;

          case 'array':
          this.addBraces('[]');
          for (var i in this.value) {
            this.push(this.value[i]);
          }
          break;

          case 'hash':
          this.addBraces('{}');
          for (var i in this.value) {
            this.addKey(i, this.value[i]);
          }
        }
        return this.wrap;
      };

      // destructor
      this.destroy = function() {
        for (var i in this) {
          delete this[i];
        }
      };

      /* initialisation */

      //string value
      if (typeof(data) !== 'object') {
        this.type  = 'string';
        this.value = data + '';
      }

      //array value
      else if (data.constructor.toString().match('Array')) {
        this.type  = 'array';
        this.value = $.map(data, function(d) {
          return new DSElement(d, self);
        });
      }

      //hash value
      else {
        this.type = 'hash';
        this.keys = [];
        for (var i in data) {
          this.keys.push(i);
        }
        this.keys = this.keys.sort(ignoreCases);
        this.value = {};
        $.each(this.keys, function(i, key) {
          self.value[key] = new DSElement(data[key], self);
        });
      }
    };

    var data = {};
    try {
      data = parse(el[isReadonly ? 'text' : 'val']().toString());
    }
    catch(e) {
      return;
    }
    
    if (!data) {
      return;
    }

    data = new DSElement(data, undefined, el, isReadonly);
    data.updateText();
    
    if (isReadonly) {
      $('<div class="-ds-readonly">').append($('<pre>').append(data.display())).appendTo(el.empty());
      return;
    }

    var error   = $('<p class="-ds-error">').hide();
    var wrapper = $('<div class="-ds-editable">')
      .html('<div class="-ds-tab"><a class="selected" href="#editor">Editor</a><a href="#source">Source</a></div><div class="-ds-tab-div"></div><div class="-ds-tab-div"></div>')
      .replaceAll(el).children().last().append(el).prev().append($('<pre>').append(data.display().addClass('_ds_toplevel'))).parent().before(error);

    new DSTabs($('a', wrapper), $('.-ds-tab-div', wrapper));

    // event method if text is changed, or form is reset
    var reset = function() {
      closeMenu();
      if (data && data.destroy) {
        data.destroy();
      }
      setTimeout(
        function() {
          if ($.trim(el.val()) === '') {
            el.val('{}');
          }
          try {
            data = parse(el.val());
          }
          catch(e) {
            error.html(e).show();
            $('._ds_toplevel', wrapper).empty();
            return;
          }
          error.hide();
          data = new DSElement(data, undefined, el, isReadonly);
          data.updateText();
          $('._ds_toplevel', wrapper).replaceWith(data.display().addClass('_ds_toplevel'));
        }, 100
      );
    };

    el.bind({change: reset}).parents('form').bind({reset: reset});
  };

  $.fn.datastructure = function () {

    this.each(function() {

      new $.datastructure(this);
    });

    return this;

  };
})(jQuery);
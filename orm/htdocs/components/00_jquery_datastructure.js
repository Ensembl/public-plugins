/**
 * datastructure
 * jQuery plugin to make a user friendly editor for perl hash datastructures
 * TODO - needs optimisation
 * TODO - allow hash keys to contain spaces - encode spaces while setting the key as className
 */

(function($) {
  
  $.datastructure = function (el) {

    el = $(el);
    var data = {};

    try {
      data = eval('(' + el.val().replace(/\=>/gm, ':') + ')');
    }
    catch (e) {
      //TODO
      return;
    }

    // Tabs class
    var HeTabs = function(buttons, tabs, active) {
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
    var HeMenu = {
      construct: function() {
        var self = this;
        if (this.el) return;
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
            .html('<a href="#hash"><span class="-hc-sel">Make </span>Hash</a><a href="#array"><span class="-hc-sel">Make </span>Array</a><a href="#string"><span class="-hc-sel">Make </span>String</a>')
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
              .append($('<input>').attr({type: 'text'}).keypress(function(e) { if (e.keyCode == 27 || e.which == 27) { closeMenu(); } } ))
              .append('<input type="submit" value="Save">')
            )
          )
        });
        new HeTabs($('#_ds_menu_tab a', this.el), $('div.-ds-tab-div', this.el));
        $('#_ds_menu_tab a', this.el).bind('click', function() {
          var type = this.href.split('#').pop();
          setTimeout(function() {
            $('form._ds_form_' + type +' input[type=text]').focus().select();
          }, 100);
        });
      },

      init: function(heEl, event) {
        var self = this;
        this.construct();
        closeMenu();
        this.heEl = heEl;
        $('#_ds_error').hide();
        $('#_ds_menu_tab a').filter('[href=#' + this.heEl.type + ']').trigger('click');
        $('form._ds_form input[type=text]', this.el).val(this.heEl.type == 'string' ? this.heEl.value || '' : '');
        $('form._ds_form', this.el).unbind('submit').submit(function(e) {
          e.preventDefault();
          try {
            self.heEl.modify((this.className.match(/_ds_form_([a-z]+)/) || []).pop(), $('input[type=text]', this).val());
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
    var HeKeyMenu = {
      construct: function() {
        if (this.el) return;
        this.el = $('<div>').attr({id: '_ds_key_menu', 'class': '-ds-menu'})
          .append('<p id="_ds_key_error" class="-ds-error">')
          .append($('<form>').append($('<input>').attr({type: 'text'}).bind({
            keypress: function(e) {
              if (e.keyCode == 27 || e.which == 27) {
                closeMenu();
              }
            },
            blur: function() {
              closeMenu();
            }
          })))
          .appendTo(document.body).hide();
      },
      init: function(heEl, event, eventTarget) {
        var self = this;
        this.construct();
        closeMenu();
        this.heEl = heEl;
        this.span = eventTarget;
        $('#_ds_key_error').hide();
        $('input', this.el.css({left: event.pageX + 'px', top: event.pageY + 'px'}).show()).val(this.span.innerHTML).focus().select();
        $('form', this.el).bind({'submit': function(event) {
          event.preventDefault();
          var newKey = $('input', this).val();
          if (newKey) {
            try {
              self.heEl.renameKey(self.span, newKey);
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

    // private method to close all popup menus
    var closeMenu = function() {
      $('#_ds_menu, #_ds_key_menu').hide();
    };

    //private class for each Element
    var HeElement = function(data, parent, ta) {
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

      //private sorting method
      var sortAlpha = function(a, b) {
        a = a.toLowerCase();
        b = b.toLowerCase();
        return a > b && 1 || a < b && -1 || 0;
      };

      //updates the text representation of hash in the textarea
      this.updateText = function() {
        this.parent ? this.parent.updateText() : this.ta.val(this.toString());
      }

      //add keys to hash
      this.addKey = function(key, val, doModify) {
        var nextKey = false;
        if (doModify) {
          this.value[key] = val;
          this.keys.push(key);
          this.keys = this.keys.sort(sortAlpha);
          for (var i in this.keys) {
            if (this.keys[i] == key) {
              nextKey = this.keys[parseInt(i) + 1];
              break;
            }
          }
          if (nextKey) {
            nextKey = $('>span._ds_key_' + nextKey, this.el).first().prev();
          }
        }
        var spans = [$('<span>').html(n + p + t), $('<span class="-ds-hil _ds_key _ds_key_' + key + '">').html(key), $('<span>').html(' =&gt; '), val.display(this.indent + 1)];
        for (var i in spans) {
          nextKey ? nextKey.before(spans[i]) : this.el.append(spans[i]);
        }
        $('>span._ds_key', this.el).bind({
          click: function(event) {
            self.getKeyMenu(event, this);
          }
        }).prev().bind({
          mouseover: function(event) {
            event.stopImmediatePropagation();
            $(this).addClass('-ds-remove-button');
            $.each([this, this.nextSibling, this.nextSibling.nextSibling, this.nextSibling.nextSibling.nextSibling], function() { $(this).addClass('-ds-remove')} );
          },
          mouseout: function() {
            $(this).removeClass('-ds-remove-button');
            $.each([this, this.nextSibling, this.nextSibling.nextSibling, this.nextSibling.nextSibling.nextSibling], function() { $(this).removeClass('-ds-remove')} );
          }, 
          click: function(event) {
            event.stopImmediatePropagation();
            self.removeKey(this.nextSibling);
          }
        });
      };
      
      this.renameKey = function(span, newKey) {
        var oldKey = span.innerHTML;
        if (oldKey == newKey) {
          return;
        }
        this.checkKey(newKey);
        var k2 = [newKey];
        for (var i in this.keys) {
          if (this.keys[i] != oldKey) {
            k2.push(this.keys[i]);
          }
        }
        this.keys = k2.sort(sortAlpha);
        delete k2;
        this.value[newKey] = this.value[oldKey];
        delete this.value[oldKey];
        $(span).removeClass('_ds_key_' + oldKey).addClass('_ds_key_' + newKey).html(newKey);
        this.updateText();
      };
      
      this.removeKey = function(span) {
        var key = span.innerHTML;
        var k2 = [];
        for (var i in this.keys) {
          if (this.keys[i] != key) {
            k2.push(this.keys[i]);
          }
        }
        this.keys = k2.sort(sortAlpha);
        delete k2;
        delete this.value[key];
        $.each([span.previousSibling, span.nextSibling.nextSibling, span.nextSibling, span], function() { $(this).remove(); });
        closeMenu();
        this.updateText();
      };
      
      this.removeArrVal = function(span) {
        var i = -1;
        var s = span;
        while (s = s.previousSibling) {
          i++;
        }
        this.value = this.value.splice(0, Math.round(i/2)).concat(this.value.splice(1));
        $.each([span.previousSibling, span], function() { $(this).remove(); });
        closeMenu();
        this.updateText();
      };
      
      this.checkKey = function(key) {
        if (key.match(' ')) {
          throw 'Hash key should not contain spaces';
        }
        if ($.grep(this.keys, function(a) { return a == key; }).length) {
          throw 'Duplicate key';
        }
      };

      //add element to array
      this.push = function(val, doModify) {
        if (doModify) {
          this.value.push(val);
          //TODO - sort this.value
        }
        this.el.append($('<span>').html(n + p + t).bind({
          mouseover: function(event) {
            event.stopImmediatePropagation();
            $(this).addClass('-ds-remove-button');
            $.each([this, this.nextSibling], function() { $(this).addClass('-ds-remove')} );
          },
          mouseout: function() {
            $(this).removeClass('-ds-remove-button');
            $.each([this, this.nextSibling], function() { $(this).removeClass('-ds-remove')} );
          }, 
          click: function() {
            self.removeArrVal(this.nextSibling);
          }
        }), val.display(this.indent + 1));
      };

      //change string value
      this.string = function(val, doModify) {
        if (doModify) {
          this.value = val;
          this.el.empty();
        }
        this.el.append($('<span class="-ds-hil _ds_string">').html(val || '<i>undef</i>').bind({ click: function(e) { self.getMenu(e); }}));
      };
      
      //returns the final modified string equivalent of the hash
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
        };
      };
      
      this.modify = function(type, value) {
        if (type == 'hash') {
          this.checkKey(value);
        }
        if (this.type != type) {
          if (this.type != 'string') {
            for (var i in this.value) {
              this.value[i].destroy();
              delete this.value[i];
            }
          }
          this.keys = [];
          this.value = '';
          this.el.empty();
          this.removeWrapper();
        }
        this.type = type;
        switch(this.type) {
          case 'string':
          this.string(value, true);
          break;

          case 'array':
          if (!this.value) {
            this.addArrayWrapper();
            this.value = [];
          }
          if (value) this.push(new HeElement(value, this), true);
          break;

          case 'hash':
          if (!this.value) {
            this.addHashWrapper();
            this.value = {};
          }
          if (value) this.addKey(value, new HeElement('', this), true);
        }
        this.updateText();
      };

      //returns the left click menu element
      this.getMenu = function(event) {
        HeMenu.init(this, event);
      };
      
      this.getKeyMenu = function(event, eventTarget) {
        HeKeyMenu.init(this, event, eventTarget);
      };
      
      this.removeWrapper = function() {
        $('span._ds_wrap', this.wrap).remove();
      };

      this.addArrayWrapper = function() {
        this.wrap.prepend($('<span class="_ds_wrap">').html('[')).append($('<span class="-ds-hil _ds_wrap">').html(n + p + ']').bind({ click: function(e) { self.getMenu(e); }}));
      };
      
      this.addHashWrapper = function() {
        this.wrap.prepend($('<span class="_ds_wrap">').html('{')).append($('<span class="-ds-hil _ds_wrap">').html(n + p + '}').bind({ click: function(e) { self.getMenu(e); }}));
      };

      //method to display data
      this.display = function(indent) {
        this.indent = indent || 1;
        for (var i = 0; i < this.indent - 1; i++) p += '  ';

        switch(this.type) {
          case 'string':
          this.string(this.value);
          break;

          case 'array':
          this.addArrayWrapper();
          for (var i in this.value) {
            this.push(this.value[i]);
          }
          break;

          case 'hash':
          this.addHashWrapper();
          for (var i in this.value) {
            this.addKey(i, this.value[i]);
          }
        };
        return this.wrap;
      };

      this.destroy = function() {
        for (var i in this) {
          delete this[i];
        }
      };
    
      //string value
      if (typeof(data) != 'object') {
        this.type  = 'string';
        this.value = data + '';
      }
      
      //array value
      else if (data.constructor.toString().match('Array')) {
        this.type  = 'array';
        this.value = $.map(data, function(d) {
          return new HeElement(d, self);
        });
      }
      
      //hash value
      else {
        this.type = 'hash';
        this.keys = [];
        for (var i in data) {
          this.keys.push(i);
        }
        this.keys = this.keys.sort(sortAlpha);
        this.value = {};
        $.each(this.keys, function(i, key) {
          self.value[key] = new HeElement(data[key], self);
        });
      }
    };
    
    data = new HeElement(data, undefined, el);
    data.updateText();

    var wrapper = $('<div>')
      .html('<div class="-ds-tab"><a class="selected" href="#editor">Editor</a><a href="#source">Source</a></div><div class="-ds-tab-div"></div><div class="-ds-tab-div"></div>')
      .replaceAll(el).children().last().append(el).prev().append($('<pre>').append(data.display())).parent();

    new HeTabs($('a', wrapper), $('.-ds-tab-div', wrapper));

    var reset = function() {
      delete data;
      setTimeout(
        function() {
          if ($.trim(el.val()) == '') {
            el.val('{}');
          }
          el.replaceAll(wrapper).datastructure();
          $('#_ds_menu, #_ds_key_menu').remove();
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
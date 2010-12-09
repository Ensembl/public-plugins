Ensembl.extend({
  initialize: function () {
    this.base();
    new FixedNavigator($('#nav').get()[0], 74, 2);
  }
});

function FixedNavigator(nav, top, margin) {
  if (!nav) return;
  this.nav = nav;
  this.top = top;
  this.margin = margin;
  this.getScroll = function() {
		var scrOfY = 0;
		if (typeof(window.pageYOffset) == 'number') {
			scrOfY = window.pageYOffset;
		}
		else if (document.body && (document.body.scrollLeft || document.body.scrollTop)) {
			scrOfY = document.body.scrollTop;
		}
		else if (document.documentElement && (document.documentElement.scrollLeft || document.documentElement.scrollTop)) {
			scrOfY = document.documentElement.scrollTop;
		}
		return scrOfY;
	};
	var self = this;
	if (window.addEventListener) {
    window.addEventListener('scroll', function() {
      var scroll = self.getScroll();
      self.nav.style.position = scroll < self.top ? 'absolute' : 'fixed';
      self.nav.style.top = scroll < self.top ? '' : self.margin + 'px';
    }, false);
	}
	else if (window.attachEvent) {
    window.attachEvent('onscroll', function() {
      var scroll = self.getScroll();
      self.nav.style.top = scroll < self.top ? '' : (scroll + self.margin) + 'px';
    });
  }
}
package EnsEMBL::Web::Document::HTML::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  $_[0]->print( qq(
    <div class="twocol-right right unpadded print_hide">
      <a href="http://www.ensembl.org/info/about/intro.html">About&nbsp;Ensembl</a> | 
      <a href="http://www.ensembl.org/info/about/contact/">Contact&nbsp;Us</a> | 
      <a href="/info/website/help/">Help</a> 
    </div>
    <div class="twocol-right right unpadded screen_hide_block">
      helpdesk\@ensembl.org
    </div>) 
  );
}

1;


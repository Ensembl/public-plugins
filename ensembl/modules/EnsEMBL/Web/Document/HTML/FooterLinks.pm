package EnsEMBL::Web::Document::HTML::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  $_[0]->print( qq(
    <div class="twocol-right right unpadded print_hide">
      <a href="http://www.ensembl.org/info/about/intro.html" class="constant">About&nbsp;Ensembl</a> | 
      <a href="http://www.ensembl.org/info/about/legal/privacy.html" class="constant">Privacy&nbsp;Policy</a> | 
      <a href="http://www.ensembl.org/info/about/contact/" class="constant">Contact&nbsp;Us</a>      
    </div>
    <div class="twocol-right right unpadded screen_hide_block">
      helpdesk\@ensembl.org
    </div>) 
  );
}

1;


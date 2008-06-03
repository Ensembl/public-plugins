package EnsEMBL::Web::Document::HTML::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  $_[0]->print( qq(
    <div class="twocol-right right unpadded">
      <a href="http://www.ensembl.org/info/about/">About&nbsp;Ensembl</a> | 
      <a href="http://www.ensembl.org/info/about/contact/">Contact&nbsp;Us</a> | 
      <a href="/info/website/help/">Help</a> 
    </div>) 
  );
}

1;


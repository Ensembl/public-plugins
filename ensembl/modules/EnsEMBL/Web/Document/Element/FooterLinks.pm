package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  return qq(
    <div class="twocol-right right unpadded print_hide">
      <a href="/info/about/intro.html" class="constant">About&nbsp;Ensembl</a> | 
      <a href="/info/about/contact/" class="constant">Contact&nbsp;Us</a> | 
      <a href="/info/website/help/" class="constant">Help</a> 
    </div>
    <div class="twocol-right right unpadded screen_hide_block">
      helpdesk\@ensembl.org
    </div>
  );
}

1;


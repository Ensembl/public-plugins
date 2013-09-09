package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  return qq(
    <div class="column-two right print_hide">
      <p>
        <a href="/info/about/index.html" class="constant">About&nbsp;Ensembl</a> | 
        <a href="/info/about/legal/privacy.html" class="constant">Privacy&nbsp;Policy</a> | 
        <a href="/info/about/contact/" class="constant">Contact&nbsp;Us</a>
      </p>
    </div>
    <div class="column-two right screen_hide_block">
      <p>helpdesk\@ensembl.org</p>
    </div>
  );
}

1;


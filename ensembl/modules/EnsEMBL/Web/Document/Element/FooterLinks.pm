package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  ## Note that these links always go to the live site so that the information is up-to-date
  return qq(
    <div class="column-two right print_hide">
      <p>
        <a href="http://www.ensembl.org/info/about/intro.html" class="constant">About&nbsp;Ensembl</a> | 
        <a href="http://www.ensembl.org/info/about/legal/privacy.html" class="constant">Privacy&nbsp;Policy</a> | 
        <a href="http://www.ensembl.org/info/about/contact/" class="constant">Contact&nbsp;Us</a>
      </p>
    </div>
    <div class="column-two right screen_hide_block">
      <p>helpdesk\@ensembl.org</p>
    </div>
  );
}

1;


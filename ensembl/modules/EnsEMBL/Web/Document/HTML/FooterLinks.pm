package EnsEMBL::Web::Document::HTML::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::Document::HTML;
use EnsEMBL::Web::RegObj;

our @ISA = qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

  $_[0]->printf(
    q(
    <div class="twocol-right right unpadded">
    <p>%s release %d - %s - %s
    <a class="modal_link" id="p_link" href="sorry.html">Permanent link</a> -
    <a class="modal_link" id="a_link" href="sorry.html">View in archive site</a></p>),
    $sd->ENSEMBL_SITE_NAME, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE,
    $sd->SPECIES_COMMON_NAME ? sprintf( '%s <i>%s</i> %s -', $sd->SPECIES_COMMON_NAME, $sd->SPECIES_BIO_NAME, $sd->ASSEMBLY_ID ): '',
    $sd->SPECIES_BIO_NAME,
    $sd->ASSEMBLY_ID
  );

  $_[0]->print( qq(
    <a href="http://www.ensembl.org/info/about/">About&nbsp;Ensembl</a> | 
    <a href="http://www.ensembl.org/info/about/contact/">Contact&nbsp;Us</a> | 
    <a href="/info/website/help/">Help</a> 
    </div>
    ) 
  );
}

1;


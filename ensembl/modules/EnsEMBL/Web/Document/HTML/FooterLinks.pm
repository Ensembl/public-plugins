package EnsEMBL::Web::Document::HTML::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

  my $URL = sprintf '/%s/%s/%s?%s', $ENV{'ENSEMBL_SPECIES'},$ENV{'ENSEMBL_TYPE'},$ENV{'ENSEMBL_ACTION'},$ENV{'QUERY_STRING'};

  $_[0]->printf(
    q(
    <div class="twocol-right right unpadded">
      <p>
        %s release %d - %s - %s
        <a class="modal_link" id="p_link" href="sorry.html">Permanent link</a> -
        <a class="modal_link" id="a_link" href="sorry.html">View in archive site</a><br />
	<a href="http://test-1.ensembl.org%s">test-1</a> - 
	<a href="http://test-2.ensembl.org%s">test-2</a> - 
	<a href="http://test-3.ensembl.org%s">test-3</a> - 
	<a href="http://test-4.ensembl.org%s">test-4</a> - 
	<a href="http://test-5.ensembl.org%s">test-5</a>
      </p>),
    $sd->ENSEMBL_SITE_NAME, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE,
    '',
#    $sd->SPECIES_COMMON_NAME ? sprintf( '%s <i>%s</i> %s -', $sd->SPECIES_COMMON_NAME, $sd->SPECIES_BIO_NAME, $sd->ASSEMBLY_ID ): '',
#    $sd->SPECIES_BIO_NAME,
#    $sd->ASSEMBLY_ID,
    $URL,
    $URL,
    $URL,
    $URL
  );
  $_[0]->print( qq(
      <a href="http://www.ensembl.org/info/about/">About&nbsp;Ensembl</a> | 
      <a href="http://www.ensembl.org/info/about/contact/">Contact&nbsp;Us</a> | 
      <a href="/info/website/help/">Help</a> 
    </div>) 
  );
}

1;


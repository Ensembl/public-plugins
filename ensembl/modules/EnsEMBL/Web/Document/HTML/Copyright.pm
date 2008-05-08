package EnsEMBL::Web::Document::HTML::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::Document::HTML;
use EnsEMBL::Web::RegObj;

our @ISA = qw(EnsEMBL::Web::Document::HTML);

sub render {
  my @time = localtime();
  my $year = @time[5] + 1900;

  ## Stable archive link for current release
  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $stable_URL = sprintf "http://%s.archive.ensembl.org%s",
      CGI::escapeHTML($species_defs->ARCHIVE_VERSION), CGI::escapeHTML($ENV{'REQUEST_URI'});

  $_[0]->print( qq(
    <div class="twocol-left left unpadded">
      <a href="http://www.sanger.ac.uk"><img src="/img/wtsi_rev.png" alt="WTSI" title="Wellcome Trust Sanger Institute" /></a>
      <a href="http://www.ebi.ac.uk"><img src="/img/ebi_new.gif" alt="EMBL-EBI" title="European BioInformatics Institute" /></a>
      &copy; $year <a href="http://www.sanger.ac.uk/" class="nowrap">WTSI</a> /
      <a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EBI</a>.<br />
      Ensembl receives major funding from the Wellcome Trust.<br />
      Our <a href="/info/about/credits.html">credits page</a> includes additional current and previous funding.
    </div>) 
  );
}

1;


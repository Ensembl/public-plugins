package EnsEMBL::Web::Document::HTML::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;
use CGI qw(escapeHTML);
use EnsEMBL::Web::Document::HTML;
use EnsEMBL::Web::RegObj;

our @ISA = qw(EnsEMBL::Web::Document::HTML);

sub new { return shift->SUPER::new( 'sitename' => '?' ); }

sub sitename    :lvalue { $_[0]{'sitename'};   }

sub render {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;

  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

  my $URL = sprintf '/%s/%s/%s?%s', $ENV{'ENSEMBL_SPECIES'},$ENV{'ENSEMBL_TYPE'},$ENV{'ENSEMBL_ACTION'},$ENV{'QUERY_STRING'};

  $self->printf(
    q(
    <div class="twocol-left left unpadded">
        %s release %d - %s - %s
      &copy; <a href="http://www.sanger.ac.uk/" class="nowrap">WTSI</a> /
      <a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EBI</a>
    <br />
        <a class="modal_link" id="p_link" href="sorry.html">Permanent link</a> -
        <a class="modal_link" id="a_link" href="sorry.html">View in archive site</a>
    </div>
      ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE,
    '',
    $URL,
    $URL,
    $URL,
    $URL
  );

}

1;


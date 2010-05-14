package EnsEMBL::Web::Document::HTML::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;
use URI::Escape qw(uri_escape);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::HTML);

sub new { return shift->SUPER::new('sitename' => '?'); }

sub sitename    :lvalue { $_[0]{'sitename'};   }

sub render {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;

  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

  my $you_are_here = $ENV{'REQUEST_URI'};
  my $referer      = uri_escape($you_are_here);
  my $stable_URL   = uri_escape('http://'. $sd->ARCHIVE_VERSION .'.archive.ensembl.org'. $you_are_here);

  $self->printf(
    q(
    <div class="twocol-left left unpadded">
        %s release %d - %s
      &copy; <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap">WTSI</a> /
      <a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EBI</a></span>
      <span class="screen_hide_inline">WTSI / EBI<br />http://%s</span>
    ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME,
    );
  
  $self->printf('<div class="print_hide">'); 
  unless ($ENV{'ENSEMBL_TYPE'} =~ /Help|Account|UserData/) {
    $self->printf(
      q(
      <br />
        <a class="modal_link" id="p_link" href="%s">Permanent link</a>
      ),
    '/Help/Permalink?url='.$stable_URL,
    );
    unless ($you_are_here =~ /html$/ && $you_are_here ne '/index.html') {
      ## Omit archive links from static content, which tends to change a lot
      $self->printf(
        q(
         - <a class="modal_link" id="a_link" href="%s">View in archive site</a>
        ),
      '/Help/ArchiveList?url='.$referer,
      );
    }
  }
  $self->print('</div></div>');

}

1;


package EnsEMBL::Web::Document::Element::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;
use URI::Escape qw(uri_escape);
use EnsEMBL::Web::RegObj;

use base qw(EnsEMBL::Web::Document::Element);

sub new { return shift->SUPER::new('sitename' => '?'); }

sub sitename    :lvalue { $_[0]{'sitename'};   }

sub content {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;

  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

  my $you_are_here = $ENV{'REQUEST_URI'};
  my $stable_URL   = uri_escape('http://' . $sd->ARCHIVE_VERSION . '.archive.ensembl.org');

  $self->printf(
    q(
    <div class="twocol-left left unpadded">
        %s release %d - %s
      &copy; <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap constant">WTSI</a> /
      <a href="http://www.ebi.ac.uk/" class="nowrap constant">EBI</a></span>
      <span class="screen_hide_inline">WTSI / EBI<br />http://%s</span>
    ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME,
    );
  
  $self->printf('<div class="print_hide">'); 
  unless ($ENV{'ENSEMBL_TYPE'} =~ /Help|Account|UserData/) {
    $self->print(
      qq{
      <br />
        <a class="modal_link" id="p_link" href="/Help/Permalink?url=$stable_URL">Permanent link</a>
      }
    );
    unless ($you_are_here =~ /html$/ && $you_are_here ne '/index.html') {
      ## Omit archive links from static content, which tends to change a lot
      $self->print(
        '
         - <a class="modal_link" id="a_link" href="/Help/ArchiveList">View in archive site</a>
        '
      );
    }
  }
  $self->print('</div></div>');

}

1;


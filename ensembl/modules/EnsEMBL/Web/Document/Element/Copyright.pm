package EnsEMBL::Web::Document::Element::Copyright;

### Replacement copyright notice for www.ensembl.org

use strict;

use URI::Escape qw(uri_escape);

use base qw(EnsEMBL::Web::Document::Element);

sub new {
  return shift->SUPER::new({
    %{$_[0]},
    sitename => '?'
  });
}

sub sitename    :lvalue { $_[0]{'sitename'};   }

sub content {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;
  my $html;

  my $sd = $self->species_defs;

  my $you_are_here = $ENV{'REQUEST_URI'};
  my $stable_URL   = uri_escape('http://' . $sd->ARCHIVE_VERSION . '.archive.ensembl.org');

  $html .= sprintf(
    q(
    <div class="column-two left">
      <p>%s release %d - %s &copy;
        <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap constant">WTSI</a> /
        <a href="http://www.ebi.ac.uk/" class="nowrap constant">EBI</a></span>
        <span class="screen_hide_inline">WTSI / EBI<br />http://%s</span>
      </p>
    ),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME,
    );
  
  $html .= '<p class="print_hide">'; 
  unless ($ENV{'ENSEMBL_TYPE'} =~ /Help|Account|UserData/) {
    $html .= qq{
        <a class="modal_link" id="p_link" href="/Help/Permalink?url=$stable_URL">Permanent link</a>
    };
    unless ($you_are_here =~ /html$/ && $you_are_here ne '/index.html') {
      ## Omit archive links from static content, which tends to change a lot
      $html .= ' - <a class="modal_link" id="a_link" href="/Help/ArchiveList">View in archive site</a>';
    }
  }
  $html .= '</p></div>';
  return $html;
}

1;


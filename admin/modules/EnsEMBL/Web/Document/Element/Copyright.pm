package EnsEMBL::Web::Document::Element::Copyright;

use strict;

sub content {
  my $self = shift;
  my @time = localtime();
  my $year = @time[5] + 1900;
  my $html;

  my $sd = $self->species_defs;

  return sprintf(q(
    <div class="twocol-left left unpadded">
        %s Admin for release %d - %s
      &copy; <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap constant">WTSI</a> /
      <a href="http://www.ebi.ac.uk/" class="nowrap constant">EBI</a></span>
      <span class="screen_hide_inline">WTSI / EBI<br />http://%s</span>
      <p>&nbsp;</p>
    </div>),
    $sd->ENSEMBL_SITETYPE, $sd->ENSEMBL_VERSION,
    $sd->ENSEMBL_RELEASE_DATE, $sd->ENSEMBL_SERVERNAME)}

1;
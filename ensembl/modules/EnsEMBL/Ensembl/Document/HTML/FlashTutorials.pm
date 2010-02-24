package EnsEMBL::Ensembl::Document::HTML::FlashTutorials;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
 
  my $html;
  my @movies;

  if (scalar(@movies)) {
 
    $html = qq(<h2>Online Workshops</h2>

<p>The tutorials listed below are Flash animations of some of our training presentations, with added popup notes in place of a soundtrack. We are gradually adding to the list, so please check back regularly (the list will also be included in the bimonthly Release Email, which is sent to the <a href="/info/about/contact/mailing.html">ensembl-announce mailing list</a>).</p>
<p>Please note that files are around 3MB per minute, so if you are on a dialup connection, playback may be jerky.</p>

<table class="ss tint">
<tr>
  <th style="width:60%">Title</th>
  <th style="width:20%">Running time (minutes)</th>
</tr>
);

    ## Loop through movie records and output table rows

    $html .= "</table>";
  }

  return $html;
}

}

1;

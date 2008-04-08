package EnsEMBL::Ensembl::Document::HTML::FlashTutorials;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  
  my $html = qq(
<table class="ss tint">
<tr>
  <th style="width:60%">Title</th>
  <th style="width:20%">Running time (minutes)</th>
</tr>
);

  $html .= "</table>";

## Loop through movie records and output table rows

  return $html;
}

}

1;

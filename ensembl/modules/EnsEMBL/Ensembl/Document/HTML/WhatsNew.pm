package EnsEMBL::Ensembl::Document::HTML::WhatsNew;

### This module outputs two alternative tabbed panels for the Ensembl homepage
### 1) the "About Ensembl" blurb
### 2) A selection of news headlines, based on the user's settings or a default list

use strict;
use warnings;

use EnsEMBL::Web::RegObj;

{

sub render {

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $release_id = $species_defs->ENSEMBL_VERSION;
  my $user = $EnsEMBL::Web::RegObj::ENSEMBL_WEB_REGISTRY->get_user;

  my $html = qq(<div class="species-news">
      <h2 class="first">What's New in Ensembl Release 50</h2>
      <ul>
      <li>Cleaner interface!</li>
      <li>Exciting new navigation!</li>
      <li>Faster!</li>
      <li>Some other stuff we haven't done yet...</li>
      </ul>
    </div>
);

  $html .= qq(<h2>Latest Blog Entries</h2>
      <ul>
        <li>New Release notes and BAC clones in mouse</li>
        <li>Ensembl US East Coast Tour</li>
        <li>March workshops, release and down time</li>
        <p><a href="http://ensembl.blogspot.com/">Go to Ensembl blog &rarr;</a></p>
      </ul>);

=pod
  if ($species_defs->ENSEMBL_LOGINS) {
    if ($user && $user->id) {
      #if (!$filtered) {
        $html .= qq(<p>Go to <a href="/common/user/account?tab=news">your account</a> to customise this news panel</p>);
      #}
    }
    else {
      $html .= qq(<p><a href="javascript:login_link();">Log in</a> to see customised news &middot; <a href="/common/user/register">Register</a></p>);
    }
  }
=cut
  return $html;
}

}

1;

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
      <h2 class="first">What's New in Ensembl Release 49 (March 2008)</h2>
      <ul>
      <li><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Multi/newsview?rel=49#cat2" style="text-decoration: none;">Release schedule</a> (<i>all species</i>)</li>
      <li><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Pongo_pygmaeus/newsview?rel=49#cat2" style="text-decoration: none;">New species - Orangutan</a> (<span class="latin">Pongo pygmaeus</span>)</li>
      <li><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Equus_caballus/newsview?rel=49#cat2" style="text-decoration: none;">New species - Horse</a> (<i>Equus caballus</i>)</li>
      <li><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Takifugu_rubripes/newsview?rel=49#cat2" style="text-decoration: none;">New genebuild - Fugu</a> (<i>Takifugu rubripes</i>)</li>
      <li><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Drosophila_melanogaster/newsview?rel=49#cat2" style="text-decoration: none;">New import of Fly database</a> (<i>Drosophila melanogaster</i>)</li>
      <p><a href="http://ensweb-03.internal.sanger.ac.uk:10000/Multi/newsview?rel=current">More news &rarr;</a></p>
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

  return $html;
}

}

1;

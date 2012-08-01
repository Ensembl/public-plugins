package EnsEMBL::Web::Document::HTML::SpeciesList;

## Alternative species listing style, that can show multiple links per species

use strict;

sub render {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  my @species      = sort $species_defs->valid_species;
  my $healthchecks = $species_defs->databases->{'DATABASE_HEALTHCHECK'};
  my $user         = $self->{'user'};

  return '' unless $user && $user->is_member_of($species_defs->ENSEMBL_WEBADMIN_ID);

  my $html         = '';

  if ($healthchecks) {
    $html .= qq(
<h2>Healthchecks</h2>
<ul>
  <li><a href="/Healthcheck/Summary">Healthcheck summary</a>
    <ul>
      <li><a href="/Healthcheck/Details/Species">Species</a></li>
      <li><a href="/Healthcheck/Details/DBType">Database type</a></li>
      <li><a href="/Healthcheck/Details/Database">Database name</a></li>
      <li><a href="/Healthcheck/Details/Testcase">Testcase</a></li>
      <li><a href="/Healthcheck/Details/Team">Team responsible</a></li>
    </ul>
  </li>
  <li><a href="/Healthcheck/Database">List of databases</a></li>
</ul>
);
  }

  $html .= qq(<h3>Species</h3><div class="admin-species">);

  for (@species) {
    (my $name = $_) =~ s/_/ /g;

    $html .= qq(<div class="species-box">);
    $html .= qq(<span class="sp-img"><img height="48" width="48" src="/i/species/48/$_.png" alt="$name" /></span><div><span>$name</span>);
    if ($healthchecks) {
      $html .= qq(<br /><a href="/$_/Healthcheck/Details/Species">Healthcheck</a> 
          | <a href="http://staging.ensembl.org/$_/">View on staging</a>);
    }
    $html .= qq(</div></div>);
  }

  return qq(<div class="admin-right-box"><div class="plain-box">$html</div>);
}

1;

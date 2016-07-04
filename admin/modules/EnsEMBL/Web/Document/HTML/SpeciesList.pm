=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Document::HTML::SpeciesList;

## Alternative species listing style, that can show multiple links per species

use strict;

sub render {
  my $self          = shift;
  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my @species       = sort $species_defs->valid_species;
  my $healthchecks  = $species_defs->databases->{'DATABASE_HEALTHCHECK'};
  my $user          = $hub->user;

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
  <li><a href="/Healthcheck/HealthcheckBugs">Healthcheck Bugs</a></li>
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

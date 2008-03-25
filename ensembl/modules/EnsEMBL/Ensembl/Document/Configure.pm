package EnsEMBL::Ensembl::Document::Configure;

### Plugin menu configuration for a standard Ensembl website

use CGI qw(escapeHTML);
use EnsEMBL::Web::Root;
our @ISA  = qw(EnsEMBL::Web::Root);

sub common_menu_items {
### Addition menu items for site-specific content
### 1. Archive links
### 2. Data download link
  my($self,$doc) = @_;

  ## Links to archive sites
  my @archive_sites;
  my $species = $ENV{'ENSEMBL_SPECIES'} || $doc->species_defs->ENSEMBL_PRIMARY_SPECIES;
  my %archive_info = %{$doc->species_defs->get_config($species, 'archive')};
  my %archive_to_display = %{$archive_info{'online'}};
  my %assembly_name = %{$archive_info{'assemblies'}};
  my @archives = reverse sort keys %archive_to_display;
  foreach my $release_id (@archives) {
    next if $release_id == $doc->species_defs->ENSEMBL_VERSION;
    my $url = $archive_to_display{$release_id}; 
    (my $archive = $url) =~ s/200/ 200/;
    my $assembly = $assembly_name{$release_id};
    my $text = "e! $release_id: $archive";
    if ($ENV{'ENSEMBL_SPECIES'} && $assembly) {
      $text .= " ($assembly)";
    }
    push @archive_sites, {
      'href' => "javascript:archive('$url')",
      'text' => $text,
      'raw'  => 1,
    };
  }

  $doc->menu->add_block( 'archive', 'bulleted', 'Ensembl Archive', 'priority' => 100, 
                            'include_miniad'=>1);

  $doc->menu->add_entry(
      'archive',
      'code'    => 'other_archive_sites',
      'href'    => $archive_sites[0]{'href'},
      'raw'     => 1, 
      'text'    => 'View previous release of page in Archive!',
      'title'   => "Link to archived version of this page",
      'options' => \@archive_sites,
      'icon'  => '/img/ensemblicon.gif',
  ) unless ($URL =~/familyview/ || !@archive_sites) ;
  
  ## Stable archive link for current release
  my $stable_URL = sprintf "http://%s.archive.ensembl.org%s",
      CGI::escapeHTML($doc->species_defs->ARCHIVE_VERSION), CGI::escapeHTML($ENV{'REQUEST_URI'});

  $doc->menu->add_entry(
      'archive',
      'code'    => 'archive_link',
      'href'    => $stable_URL,
      'text'    => 'Stable Archive! link for this page',
      'icon'  => '/img/ensemblicon.gif',
  );

}

sub static_menu_items {
### Addition static-content-only menu items for site-specific content
### Stub - currently no items added
}

sub dynamic_menu_items {
### Addition dynamic-content-only menu items for site-specific content
### Stub - currently no items added
}

1;

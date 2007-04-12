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
  my $URL = CGI::escapeHTML($ENV{'REQUEST_URI'});
  my @archive_sites;
  my @releases = @{ $doc->species_defs->RELEASE_INFO || $doc->species_defs->anyother_species('RELEASE_INFO') || []};
  if (scalar(@releases)) {
    my $species = $ENV{'ENSEMBL_SPECIES'};
    my %archive_info = %{$doc->species_defs->get_config($species, 'archive')};
    my $assembly;
    foreach my $release (@releases) {
      my $number = $release->{release_id};
      if (!$species || ($assembly = $archive_info{$number})) {
        (my $link  = $release->{short_date}) =~ s/\s+//;
        my $text   = $release->{short_date};
        last if $number < $doc->species_defs->EARLIEST_ARCHIVE;
        next if $number == $doc->species_defs->ENSEMBL_VERSION;
        if ($assembly) {
          $text .= " ($assembly)";  
        }

        push @archive_sites, {
          'href' => "javascript:archive('$link')", 
          'text' => "e! $number: $text", 
          'raw'  => 1,
        };
      }
    }
  }

  if (!$doc->access_restrictions) {

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

}

sub static_menu_items {
### Addition static-content-only menu items for site-specific content
  my( $self, $doc ) = @_;

### 1. Lists of current species (not shown on info pages)
  my $URI = $doc->{_renderer}->{r}->uri;
  unless ($URI =~ m#^/info# ) {

    $doc->menu->add_block( 'species', 'bulleted', 'Select a species', 'priority' => 20);

    my @group_order = qw( Mammals Chordates Eukaryotes );
    my %spp_tree = (
      'Mammals'   => { 'label'=>'Mammals',          'species' => [] },
      'Chordates' => { 'label'=>'Other chordates',  'species' => [] },
      'Eukaryotes'=> { 'label'=>'Other eukaryotes', 'species' => [] },
    );
    ## get the info for all species
    my @species_inconf = @{$doc->species_defs->ENSEMBL_SPECIES};
    foreach my $sp ( @species_inconf) {
      my $bio_name = $doc->species_defs->other_species($sp, "SPECIES_BIO_NAME");
      my $group    = $doc->species_defs->other_species($sp, "SPECIES_GROUP") || 'default_group';
      unless( $spp_tree{ $group } ) {
        push @group_order, $group;
        $spp_tree{ $group } = { 'label' => $group, 'species' => [] };
      }
      my $hash_ref = { 'href'=>"/$sp/", 'text'=>"<i>$bio_name</i>", 'raw'=>1 };
      push @{ $spp_tree{$group}{'species'} }, $hash_ref;
    }
    ## output the info grouped by taxa
    foreach my $group (@group_order) {
      next unless @{ $spp_tree{$group}{'species'} };
      my $text = $spp_tree{$group}{'label'};
      $doc->menu->add_entry(
        'species',
        'href'=>'/',
        'text'=>$text,
        'options'=>$spp_tree{$group}{'species'}
      );
    }
  }
}

sub dynamic_menu_items {
### Addition dynamic-content-only menu items for site-specific content
### Stub - currently no items added
}

1;

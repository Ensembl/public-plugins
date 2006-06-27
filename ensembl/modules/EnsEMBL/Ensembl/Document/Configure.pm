package EnsEMBL::Ensembl::Document::Configure;

use CGI qw(escapeHTML);
use EnsEMBL::Web::SpeciesDefs;

use EnsEMBL::Web::Root;
our @ISA  = qw(EnsEMBL::Web::Root);

sub common_menu_items {
  my($self,$doc) = @_;
  $doc->menu->add_entry( 'links',
    'code' => 'vega',
    'href'  => 'http://vega.sanger.ac.uk/',
    'text'  => 'Vega',
    'icon'  => '/img/vegaicon.gif',
    'title' => "Vertebrate Genome Annotation"
  );
  $doc->menu->add_entry( 'links',
    'code' => 'pre',
    'href'  => 'http://pre.ensembl.org/',
    'text'  => 'Pre Ensembl',
    'icon'  => '/img/preicon.gif',
    'title' => "New assemblies that have yet to get into Ensembl"
  );


# Archive stuff

  my $URL = CGI::escapeHTML($ENV{'REQUEST_URI'});
  my @archive_sites;
  my @releases = @{ $doc->species_defs->RELEASE_INFO || $doc->species_defs->anyother_species('RELEASE_INFO') || []};
  if (scalar(@releases)) {
    foreach my $release (@releases) {
      (my $link  = $release->{short_date}) =~ s/\s+//;
      my $text   = $release->{short_date};
      my $number = $release->{release_id};
      last if $number == 24;
      next if $number == $doc->species_defs->ENSEMBL_VERSION;

      push @archive_sites, { 'href' => "http://$link.archive.ensembl.org$URL", 
			   'text' => "v$number $text", 
			   'raw'  => 1,
			 };
    }
  }

  $doc->menu->add_entry(
			'links',
			'code'    => 'other_archive_sites',
			'href'    => $URL,
			'text'    => 'View previous release of page in Archive!',
			'title'   => "Link to archived version of this page",
			'options' => \@archive_sites,
			'icon'  => '/img/ensemblicon.gif',
		       ) unless $URL =~/familyview/;
  
  my $stable_URL = sprintf "http://%s.archive.ensembl.org%s",
    CGI::escapeHTML($doc->species_defs->ARCHIVE_VERSION), CGI::escapeHTML($ENV{'REQUEST_URI'});

  $doc->menu->add_entry(
			'links',
			'code'    => 'archive_link',
			'href'    => $stable_URL,
			'text'    => 'Stable Archive! link for this page',
			'icon'  => '/img/ensemblicon.gif',
  );

  $doc->menu->add_entry( 'links',
			 'code' => 'archive',
			 'href' => 'http://archive.ensembl.org',
			 'text' => 'Archive! sites',
			 'icon'  => '/img/ensemblicon.gif',
  );

  $doc->menu->add_entry(
    'links',
    'href' => 'http://trace.ensembl.org/',
    'text' => 'Trace server',
    'title' => "trace.ensembl.org - trace server"
  );
  $doc->menu->add_entry(
    'whattodo',
    'href'=>"/info/data/download.html",
    'text' => 'Download data'
  );
}

sub static_menu_items {
  my( $self, $doc ) = @_;
# don't show species links on main home page
  unless( $ENV{'REQUEST_URI'} eq '/index.html' ) {
    $doc->menu->add_block( 'species', 'bulleted', 'Select a species', 'priority' => 20 );

  # do species popups from config
    my @group_order = qw( Mammals Chordates Eukaryotes );
    my %spp_tree = (
      'Mammals'   => { 'label'=>'Mammals',          'species' => [] },
      'Chordates' => { 'label'=>'Other chordates',  'species' => [] },
      'Eukaryotes'=> { 'label'=>'Other eukaryotes', 'species' => [] },
    );
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

}

1;

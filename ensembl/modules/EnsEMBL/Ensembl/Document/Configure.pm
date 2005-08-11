package EnsEMBL::Ensembl::Document::Configure;

use CGI qw(escapeHTML);

sub common_menu_items {
  my($self,$doc) = @_;
  $doc->menu->add_entry( 'links',
    'href'  => 'http://vega.sanger.ac.uk/',
    'text'  => 'Vega',
    'icon'  => '/img/vegaicon.gif',
    'title' => "Vertebrate Genome Annotation"
  );
  $doc->menu->add_entry( 'links',
    'href'  => 'http://pre.ensembl.org/',
    'text'  => 'Pre Ensembl',
    'icon'  => '/img/preicon.gif',
    'title' => "New assemblies that have yet to get into Ensembl"
  );
  $doc->menu->add_entry(
    'links',
    'href' => 'http://trace.ensembl.org/',
    'text' => 'Trace server',
    'title' => "trace.ensembl.org - trace server"
  );

  $doc->menu->add_entry( 'links',
    'code' => 'archive',
    'href' => 'http://archive.ensembl.org',
    'text' => 'Archive! sites'
  );

  my $URL = sprintf "http://%s.archive.ensembl.org%s",
    CGI::escapeHTML($doc->species_defs->ARCHIVE_VERSION), CGI::escapeHTML($ENV{'REQUEST_URI'});
  $doc->menu->add_entry( 'links',
    'code' => 'archive_link',
    'href' => $URL,
    'text' => 'Stable Archive! link for this page'
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

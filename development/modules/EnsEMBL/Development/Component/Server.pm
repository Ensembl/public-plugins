package EnsEMBL::Development::Component::Server;

use strict;

sub static_tree {
  my($panel,$object) = @_;
  $panel->add_row( 'Document tree', _sub_tree( $object, '/', 0) );
  return 1;
}

sub _sub_tree {
  my( $object, $K, $i ) = @_;
  my $HTML = qq(@{['&nbsp;' x ($i*2)]}<a href="$K">@{[$object->species_defs->ENSEMBL_BREADCRUMBS->{$K}[0]]}</a><br />\n);
  foreach my $C (@{$object->species_defs->ENSEMBL_CHILDREN->{$K}||[]})  {
    $HTML .= _sub_tree( $object, $C, $i+3 );
  }
  return $HTML;
}

sub spreadsheet_Apache {
  my( $panel, $object ) = @_;
  $panel->add_columns(
    { 'key' => 'key',    'align' => 'left', 'title' => 'Key' },
    { 'key' => 'value',  'align' => 'left', 'title' => 'Value' },
  );
  foreach (@{$object->get_environment}) {
    $panel->add_row( $_ );
  }
  return 1;
}

sub configuration_hash {
  my( $panel, $object ) = @_;
  $panel->add_row( 'Main Storage Hash', conf_dump($panel,0,$object->species_defs->{_storage}) );
  $panel->add_row( 'MULTI Storage Hash', conf_dump($panel,0,$object->species_defs->{_multi}) );
}

sub conf_dump {
  my( $panel, $level, $hashref ) = @_;
  $panel->print( "<ul>" );
  foreach (sort keys %$hashref) {
    $panel->print( "<li><strong>$_</strong>" );
    if( $hashref->{$_} =~/HASH/ ) {
      conf_dump( $panel, $level+1, $hashref->{$_} );
    } elsif( $hashref->{$_} =~/ARRAY/ ) {
      $panel->print( " = [ ", join( ', ',@{$hashref->{$_}} )," ]" );
    } else {
      $panel->print( " = ".$hashref->{$_});
    }
    $panel->print( "</li>" );
  }
  $panel->print( "</ul>" );
}
1;


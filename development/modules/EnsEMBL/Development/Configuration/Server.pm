package EnsEMBL::Development::Configuration::Server;

use strict;
use EnsEMBL::Web::Configuration;
our @ISA = qw( EnsEMBL::Web::Configuration );

use EnsEMBL::Web::Document::Panel::Information;
use EnsEMBL::Web::Document::Panel::SpreadSheet;

sub status {
  my $self = shift;
  my $TP = $self->{page}->content->panel( 'info' );
  if( $TP ) {
    $TP->add_component_last( 'tree', 'EnsEMBL::Development::Component::Server::static_tree' );
  }
  my $panel2 = new EnsEMBL::Web::Document::Panel::SpreadSheet(
    'code'    => 'apache',
    'caption' => 'Apache Environment',
    'object'  => $self->{object},
    'status'  => 'panel_apache'
  );
  $panel2->add_component( qw(apache EnsEMBL::Development::Component::Server::spreadsheet_Apache));
  $self->{page}->content->add_panel_last( $panel2 );
  my $panel3 = new EnsEMBL::Web::Document::Panel::Information(
    'code'    => 'apache',
    'caption' => 'Ensembl SpeciesDefs configuration',
    'object'  => $self->{object},
    'status'  => 'panel_conf'
  );
  $panel3->add_component( qw(conf EnsEMBL::Development::Component::Server::configuration_hash));
  $self->{page}->content->add_panel_last( $panel3 );
}

1;


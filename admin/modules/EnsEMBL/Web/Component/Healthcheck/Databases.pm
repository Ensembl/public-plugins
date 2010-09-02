package EnsEMBL::Web::Component::Healthcheck::Databases;

use strict;
use warnings;
no warnings "uninitialized";

use DBI;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable( 1 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub content {
  my $self = shift;
  my $html;

  my @servers = ('ens-staging1', 'ens-staging2');
  my %configured_dbs;

  my $SD = $self->object->species_defs;
  my @db_types = qw(DATABASE_CORE DATABASE_OTHERFEATURES DATABASE_VARIATION DATABASE_FUNCGEN);

  foreach my $hostname (@servers) {
    $html .= "<h2>$hostname</h2><ul>";
    my $drh = DBI->install_driver('mysql');
    my @dbs = $drh->func($hostname, '3306', 'ensro', '_ListDBs');
    my $matchstring = '_core|_otherfeatures|_cdna|_variation|_funcgen|_compara';
    my $fullmatch = '('.$matchstring.')_'.$SD->ENSEMBL_VERSION.'_([a-z0-9]{2,5})';
    my $previous = ''; 
    my $indent = 1;
    foreach my $dbname (@dbs) {
      if ($dbname =~ /$matchstring/ && $dbname !~ /master/) {
        $dbname =~ /^([a-z]+_[a-z]+)/;
        my $spname = $1;
        ## Close any previous species' sublist
        if ($previous && $spname ne $previous && !$indent) {
          $html .= "</ul>";
          $indent = 1;
        }
        ## Start a new sublist if wanted
        if ($previous && $spname eq $previous && $indent) {
          $html .= '<ul>';
          $indent = 0;
        }
        #warn ">>> SPECIES $spname"; 
        if ($indent) {
          $html .= "<li><strong>$dbname</strong></li>";
        }
        else {
          $html .= "<li>$dbname</li>";
        }
        $previous = $spname;
      }
    }
    if (!$indent) {
      $html .= '</ul>';
    }
    $html .= '</ul>';
  }
  return $html;
}

1;

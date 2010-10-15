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
  $html .= '<h1>Database list</h1>';
  $html .= "<p><strong>Y/N</strong>: is this database being healthchecked?</p>";

  my @servers = ('ens-staging1', 'ens-staging2');
  my @databases = $self->object->database_names;
  my %db_check = map { $_ => 1 } @databases;
  my %configured_dbs;

  my $SD = $self->object->species_defs;
  my @db_types = qw(DATABASE_CORE DATABASE_OTHERFEATURES DATABASE_VARIATION DATABASE_FUNCGEN);

  foreach my $hostname (@servers) {
    $html .= "<h2>$hostname</h2>";
    $html .= "<ul>";
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
        if ($indent) {
          $html .= "<li><strong>$dbname</strong>";
        }
        else {
          $html .= "<li>$dbname";
        }
        $html .= $db_check{$dbname} ? ' <span style="color:red;font-weight:bold">(Y)</span>' 
                                    : ' <span style="color:green;font-weight:bold">(N)</span>';
        $html .= '</li>';
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

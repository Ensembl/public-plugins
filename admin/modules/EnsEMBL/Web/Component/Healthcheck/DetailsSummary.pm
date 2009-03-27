package EnsEMBL::Web::Component::Healthcheck::DetailsSummary;

### 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Healthcheck);
use EnsEMBL::Web::Data::HcSessionView;
use EnsEMBL::Web::Document::HTML::TwoColTable;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 1 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $species = $object->species;
  my $release = $object->release;
  my $html;

  my @dbs = @{$object->database_names};

  if (@dbs) {
    foreach my $db (@dbs) {
      my $number_run =  $object->count_tests($db);
      if ($number_run) {
        $html .= "<h2>Summary of results for $db</h2>";
        my $table = EnsEMBL::Web::Document::HTML::TwoColTable->new;

        my $text = qq(Total tests run: $number_run<br />);
        foreach (@{$self->object->result_types}) {
          my $class = 'hc-'.lc($_);
          my $count = $object->count_tests($db, $_);
          $text .= qq(<div class="$class">$_: $count</div>);
        }
        $table->add_row("Number failed", $text);

        # Names of failed tests
        my @failed_tests =   @{ $object->failed_tests($db)};

        my $failed_info;
        foreach  (@failed_tests) {
          my ($test, $type) = @$_;
          my $class = 'hc-'.lc($type);
          $failed_info .= qq(<div class="$class">
                             <a href="#$db$type$test">$test</a></div>);
        }
        $db =~ s/[a-z]+_[a-z]+_//;
        $table->add_row("Tests failed for $db", 
            (scalar(@failed_tests))." in list based on configured options<br />".$failed_info);

        $html .= $table->render;
      }
      else {
        $html .= $self->_warning('No data', "No tests run for database $db");
      }
    }
  }
  else {
    $html .= $self->_warning('No databases', "No reports available for $species in the latest healthcheck session (healthchecks may be being updated)");
  }

  return $html;
}

1;

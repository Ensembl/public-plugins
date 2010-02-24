package EnsEMBL::Web::Component::Healthcheck::SessionInfo;

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
}

sub caption {
  my $self = shift;
  return 'Last session';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $release = $object->release;
  my $info = $object->session_info($object->max_session_for_release);

  if ($info) {
    my $table = EnsEMBL::Web::Document::HTML::TwoColTable->new;

    my $html = "Start: ".$self->friendly_date($info->{'start_time'})
                  ."<br />End  : ".$self->friendly_date($info->{'end_time'});
    $table->add_row("Last run times for $release", $html);
    $table->add_row("Host", $info->{'host'} );
    $table->add_row("Database names", @{$info->{'db_names'}});
    my @groups = ref($info->{'groups'}) eq 'ARRAY' ? @{$info->{'groups'}} : ();
    $table->add_row("Tests/groups run", @groups);
    my $previous;
    for (my $count = $object->species_defs->ENSEMBL_VERSION; $count > 41; $count--) {
      $previous .= qq(<li><a href='/Healthcheck/Summary?release=$count'>$count</a>);
    }
    $table->add_row("Other release", "<ul>$previous</ul>" );

    return $table->render;
  }
  else {
    return "<p>No healthchecks have been run for this release.</p>";
  }
}

1;

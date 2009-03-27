package EnsEMBL::Web::Component::Healthcheck::FailureSummary;

### 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Healthcheck);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'Failed healthchecks';
}

sub content {
  my $self = shift;
  my $object = $self->object;

  my @species = @{ $object->species_defs->ENSEMBL_SPECIES || [] };
  my $release = $object->release;
  my $last_release = $object->release -1;

  my $html = qq(<p class="space-below" style="margin-top:1em">Tests listed as failed are of type 'PROBLEM', excluding those annotated 'manual ok', 'manual_ok_this_assembly', 'manual_ok_all_releases', 'healthcheck bug'</p>);

  my $table = EnsEMBL::Web::Document::SpreadSheet->new();

  $table->add_columns(
    { 'key' => 'species', 'title' => 'Species'},
    { 'key' => 'new_failed' ,'title' => 'Newly failed on last run', 'align' => 'center' },
    { 'key' => 'results' ,'title' => "Number of failed in v$release", 'align' => 'center' },
    { 'key' => 'previous' ,'title' => "Number of failed in v$last_release", 'align' => 'center' },
  );
  foreach my $spp ( sort @species ) {
    my $current_failed = $object->number_failed_by_species($spp, 'last', $release);
    my $previous_failed = $object->number_failed_by_species($spp, 'last', $last_release);
    my $previous_link;
    if (defined $previous_failed) {
      $previous_link = qq(<a href='/$spp/Healthcheck/Details?release=$last_release'>$previous_failed</a>);
    }
    my $new_failed = $object->number_failed_by_species($spp, 'first', $release);
    my $spp_link = qq(<a href="/$spp/Healthcheck/Details">$spp</a>);
    $table->add_row( 
          {'species'      => $spp_link,
           'new_failed'   => $new_failed,
           'results'      => $current_failed,
           'previous'     => $previous_link} 
    );
  }

  $html .= $table->render;
  return $html;
}

1;

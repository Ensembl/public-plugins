package EnsEMBL::Web::Component::Tools::Blast::HitSummary;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;

  my $job     = $object->get_requested_job({'with_requested_result' => 1});
  my $result  = $job && $job->status eq 'done' ? $job->result->[0] : undef;

  if ($result) {

    my $hit   = $result->result_data;
    my $table = $self->new_twocol;

    $table->add_row('Query location',       sprintf '%s %s to %s (%s)', $hit->{'qid'}, $hit->{'qstart'}, $hit->{'qend'}, $hit->{'qori'} == 1 ? '+' : '-');
    $table->add_row('Database location',    sprintf '%s %s to %s (%s)', $hit->{'tid'}, $hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'} == 1 ? '+' : '-');
    $table->add_row('Genomic location',     sprintf '%s %s to %s (%s)', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}, $hit->{'gori'} == 1 ? '+' : '-');
    $table->add_row('Alignment score',      $hit->{'score'});
    $table->add_row('E-value',              $hit->{'evalue'});
    $table->add_row('Alignment length',     $hit->{'len'});
    $table->add_row('Percentage identity',  $hit->{'pident'});

    return $table->render;
  }

  return $self->no_result_hit_found;
}

1;

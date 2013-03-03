package EnsEMBL::Web::Component::Tools::BlastHitSummary;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $html = '';
  my $object = $self->object;
  my $hub = $self->hub;

  my $ticket = $object->ticket;
  my $ticket_id = $ticket->ticket_id;
  my $hit_id = $hub->param('hit');
  my $result_id = $hub->param('res');
  my $hit = $object->fetch_blast_hit_by_id($result_id);

  my $summary_table = $self->new_twocol;
  $summary_table = $self->get_hit_summary_text($hit, $summary_table);
  $html .= $summary_table->render;
}

sub get_hit_summary_text {
  my ($self, $hit, $table) = @_;

  my $q_location = sprintf "%s %s to %s (%s)", $hit->{'qid'}, $hit->{'qstart'}, $hit->{'qend'}, $hit->{'qori'} == 1 ? '+' : '-';
  my $d_location = sprintf "%s %s to %s (%s)", $hit->{'tid'}, $hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'} == 1 ? '+' : '-';
  my $g_location = sprintf "%s %s to %s (%s)", $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}, $hit->{'gori'} == 1 ? '+' : '-';

  $table->add_row('Query location    :', $q_location);
  $table->add_row('Database location :', $d_location);
  $table->add_row('Genomic location  :', $g_location);


  $table->add_row('Alignment score :', $hit->{'score'});
  $table->add_row('E-value :', $hit->{'evalue'});
  $table->add_row('Alignment length :', $hit->{'len'});
  $table->add_row('Percentage identity:', $hit->{'pident'});

  return $table;
}
1;

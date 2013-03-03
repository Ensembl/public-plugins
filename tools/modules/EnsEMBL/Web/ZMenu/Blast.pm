package EnsEMBL::Web::ZMenu::Blast;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->hub->core_objects->{'tools'};
  my $ticket_name = $hub->param('tk'); 
  my $coord_range = $hub->param('bin');
  my $idx = $hub->param('idx') || 0;
  my $ticket = $object->fetch_ticket_by_name($ticket_name);
  my $ticket_id = $ticket->{'ticket_id'};  
  my $species = $hub->param('sp');   
  my (@results, $hit, $hit_id);

  if ($hub->param('hid')){
    $hit_id = $hub->param('hid');
    $hit = $object->fetch_blast_hit_by_id($hit_id);
  } else {
    @results = @{$object->get_ticket_hits_by_coords($coord_range, $ticket_id, $species)};
    my @sorted_results = sort { $b->[1]->{'score'} <=> $a->[1]->{'score'}}  @results;
    $hit = $sorted_results[$idx]->[1]; 
    $hit_id = $sorted_results[$idx]->[0];
  }

  my $query_location = $hit->{'qid'}.':'.$hit->{'qstart'}.'-'.$hit->{'qend'};
  my $genomic_location = $hit->{'gid'}.':'.$hit->{'gstart'}.'-'.$hit->{'gend'};

  $self->caption('Blast/Blat Hit');
  $self->highlight('hsp_'. $hit_id);

  $self->add_entry({
    type  => 'Query bp',
    label => $query_location
  });


  $self->add_entry({
    type  => 'Target',
    label => $hit->{'tid'},
  }) if $hit->{'db_type'} !~/latest/i;

  $self->add_entry({
    type  => 'Genomic bp',
    label => $genomic_location
  });

  $self->add_entry({
    type  => 'Score',
    label => $hit->{'score'},
  });

  $self->add_entry({
    type  => 'E-value',
    label => $hit->{'evalue'}  
  });

  $self->add_entry({
    type  => '%ID',
    label => $hit->{'pident'}
  });

  $self->add_entry({
    type  => 'Length',
    label => $hit->{'len'}
  });
  
  if (scalar @results > 1){

    my $count = scalar @results;
    my $url_template = $hub->url({
      type    => 'ZMenu', 
      action  => 'Blast', 
      tk      => $ticket_name, 
      bin     => $coord_range, 
      sp      => $species, 
      res     => $hit_id, 
      idx     => 1
    });

    $self->pagination({
      position      => $idx, 
      total         => $count, 
      url_template  => $url_template,
    });

  }

}

1;

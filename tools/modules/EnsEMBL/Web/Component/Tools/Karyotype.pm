package EnsEMBL::Web::Component::Tools::Karyotype;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::ToolsConstants;

use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object;
  my $species_defs = $hub->species_defs;

  return unless $hub->param('tk');

  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  return unless ref($ticket);

  ## We have a ticket!
  my $html;
  my $analysis_object  = $ticket->analysis->object;
  my $species = $object->deserialise($analysis_object)->{'_species'}->[0]; 
  my $chromosomes  = $species_defs->get_config($species, 'ENSEMBL_CHROMOSOMES') || [];

  if (scalar @$chromosomes && $species_defs->MAX_CHR_LENGTH) {
    my $image_config = $hub->get_imageconfig('Vkaryoblast');
    my $image = $self->new_karyotype_image($image_config);
    my $pointers = $self->get_hits($object, $ticket, $image);
    return "" unless $pointers;

    my $hide    = $hub->get_cookie_value('toggle_blast_karyotype') eq 'closed';
    $html = sprintf ('<h3><a rel ="blast_karyotype" class="toggle set_cookie %s" href="#">HSP distribution:</a></h3>',
            $hide ? 'closed' : 'open'
            );

    $image->set_button('drag', 'title' => 'Click on a chromosome');  
    $image->imagemap = 'yes';
    $image->karyotype($hub, $object, $pointers, 'Vkaryoblast', $species);  

    $html .= sprintf ('<div class="blast_karyotype"><div class="toggleable" style=%s>',
            $hide ? 'display:none' : '',
          );
    $html .= $image->render;
    $html .= '</div></div>';
  }

  return $html;
}

sub get_hits {
  my ($self, $object, $ticket, $image) = @_;
  my @hive_jobs = @{$ticket->sub_job};
  my (@results, @features);
  my $status = $ticket->status;

  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;

      @results = @{$object->rose_manager('Result')->fetch_results_by_ticket_sub_job($ticket_id, $sub_job_id)};
    }
  }


  return unless scalar @results > 0;

  my $features = $self->convert_to_drawing_parameters(\@results, $ticket);

  my $hub = $self->hub;
  my @pointers;
  my $gradient = $self->gradient;

  my $pointer_ref = $image->add_pointers($hub, {
    config_name   => 'Vkaryoblast',
    features      => $features,
    feature_type  => 'Xref',
    color         => 'gradient',
    style         => 'rharrow',
    gradient      => $gradient,
  });

  push @pointers, $pointer_ref;
  return \@pointers;
}


sub convert_to_drawing_parameters {
  my ($self, $results, $ticket) = @_;
  my $object = $self->object;
  my $ticket_name = $ticket->{'ticket_name'};
  my $features = [];
  my $hub = $self->hub;

  foreach my $result (@$results) {
    my $gzipped_serialsed_res = $result->{'result'};
    my $hit = $object->deserialise($gzipped_serialsed_res);
    my $species = $object->get_hit_species($result->{'result_id'});

    push @$features, {
      'region'    => $result->{'chr_name'}, 
      'start'     => $result->{'chr_start'}, 
      'end'       => $result->{'chr_end'}, 
      'ident'     => $hit->{'pident'},
      'strand'    => $hit->{'gori'},
      'label'     => 'Test', 
      'href'      => $hub->url({ type => 'ZMenu', action => 'Blast', 'tk' => $ticket_name, bin => 1, 'sp' => $species, 'res' => $result->{'result_id'} }), 
      'html_id'   => 'hsp_' . $result->{'result_id'} 
    }
  }

  return $features;
}

1;

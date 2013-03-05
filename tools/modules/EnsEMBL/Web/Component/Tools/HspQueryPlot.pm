package EnsEMBL::Web::Component::Tools::HspQueryPlot;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object; 
  my $html;

  return unless $hub->param('tk');

  my $ticket = $object->fetch_ticket_by_name($hub->param('tk'));
  return unless ref($ticket);

  my @hive_jobs = @{$ticket->sub_job};
  my (@results, @features);
  my $status = $ticket->status;
  
  return unless $status eq 'Completed';

  foreach my $hive_job (@hive_jobs ){
    if ($status eq 'Completed'){
      my $sub_job_id = $hive_job->sub_job_id;
      my $ticket_id = $ticket->ticket_id;

      @results = @{$object->rose_manager('Result')->fetch_results_by_ticket_sub_job($ticket_id, $sub_job_id)};
      return if scalar @results < 1;
    }
  }

  my $bucket = EnsEMBL::Web::Container::HSPContainer->new($object, $ticket, \@results);
  my $image_config = $hub->get_imageconfig('hsp_query_plot');

  my $hsp_dc = Bio::EnsEMBL::DrawableContainer->new($bucket, $image_config);
  my $image = EnsEMBL::Web::Document::Image->new($hub);
  $image->drawable_container = $hsp_dc; 
  $image->imagemap = 'yes';
  $image->set_button('drag');


  my $hide_plot = $hub->get_cookie_value('toggle_blast_queryplot') eq 'closed';
  $html = sprintf ('<h3><a rel ="blast_queryplot" class="toggle set_cookie %s" href="#">HSP distribution on query sequence:</a></h3>',
          $hide_plot ? 'closed' : 'open'
          );

  $html .= sprintf ('<div class="blast_queryplot"><div class="toggleable" style=%s>',
          $hide_plot ? 'display:none' : '',
         );

  $html .= $image->render; 
  $html .= '</div></div>';

  # Add colour key information
  my $columns = [
    {'key' => 'ftype',  'title' => 'Feature type'},
    {'key' => 'colour', 'title' => 'Colour'},
  ];
 
  my $rows;
  my $swatch    = '';
  my $legend    = '';

  my $gradient  = $self->gradient;
  my @colour_scale = $hub->colourmap->build_linear_gradient(@$gradient);

  my $i = 1;
  foreach my $step (@colour_scale) {
    my $label;

    if ($i == 1) {
      $label = "0";
    } elsif ($i == scalar @colour_scale) {
      $label = '100';
    } else {
      $label = ($i ) % 2  == 0 ? '' : ($i -1) * 10 ;
    }

    $swatch .= qq{<div style="background:#$step">$label</div>};
    $i++;
  }

  $legend = sprintf '<div class="swatch-legend">Lower %%ID  &#9668;<span>%s</span>&#9658; Higher %%ID </div>', ' ' x 33;

  push @$rows, {
    'ftype'  => {'value' => 'BLAST/BLAT hit'},
    'colour' => {'value' => qq(<div class="swatch-wrapper"><div class="swatch">$swatch</div>$legend</div>)},
  };

  my $hide    = $hub->get_cookie_value('toggle_blast_key_table') eq 'closed';
  $html .= sprintf ('<h3><a rel="blast_key_table" class="toggle set_cookie %s" href="#" >Key</a></h3>',
          $hide ? 'closed' : 'open'
          );

  my $table = $self->new_table($columns, $rows, {toggleable => 1, class => ($hide ? ' hide ' : ''), id => 'blast_key_table' });

  $html .= '<div class="blast_key_table">' . $table->render . '</div>';
  
  return $html;
}

1;

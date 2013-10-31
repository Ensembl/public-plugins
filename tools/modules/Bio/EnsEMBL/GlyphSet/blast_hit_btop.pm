package Bio::EnsEMBL::GlyphSet::blast_hit_btop;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Bio::EnsEMBL::GlyphSet);

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::Feature;

sub colour_key {return 'blast';}
sub title {}

sub features {warn "NOT IMPLEMENTED";
  my $self = shift;
  my $slice = $self->{'container'};
  my @features; 

  my $tools_object = $self->{'config'}->{'hub'}->{'_core_objects'}->{'tools'};
  return unless $tools_object;

  my $ticket = $tools_object->ticket;

  my @result_lines = @{$tools_object->get_all_hits_from_ticket_in_region($slice, $ticket->ticket_id)}; # TODO - get_all_hits_in_slice_region
  my %extra;

  my $analysis = new Bio::EnsEMBL::Analysis (
    -id               => 1,
    -logic_name       => 'blast_search', 
    -db               => undef,
    -db_version       => undef,
    -db_file          => undef, 
    -program          => 'blast',
    -program_version  => undef,
    -program_file     => undef,
    -gff_source       => undef, 
    -gff_feature      => undef,
    -module           => undef,
    -module_version   => undef,
    -parameters       => undef, 
    -created          => undef,
    -display_label    => 'test',
  );

  
  foreach (sort {$a->[1]->{'score'} <=> $b->[1]->{'score'}} @result_lines){

    my $hit = $_->[1];
    next if $hit->{'gori'} ne $self->strand;
    my $id = $_->[0];
    my $coords = $hit->{'g_coords'} || undef;
    my $identity            = sprintf("%.1f", ($hit->{'pident'} /100));
    my $colours = $self->get_colour_scale;  
    my $colour  = $colours->{$identity};
    my $slice_length = $slice->length; 
    my $db_type = $hit->{'db_type'};
    my $method = $self->{'config'}->hub->param('method');
    my $draw_btop = $slice_length < 10000 && $method =~/^blastn/i  ? 1 :undef 

    my $btop;
    if ($draw_btop) { 
      $btop  =  $db_type =~/cdna/i ?  $tools_object->map_btop_to_genomic_coords($hit, $_->[0]) : $hit->{'aln'};
      if ($btop && $hit->{'gori'} ne '1' && $hit->{'db_type'}=~/latest/i){
        $btop = $tools_object->reverse_btop($btop);
      }
    } else {
      if (lc($method) eq 'tblastn' || $db_type =~/latest/i ){
        $coords->[0]->{'start'} = $hit->{'gstart'};
        $coords->[0]->{'end'}   = $hit->{'gend'};
      } 
    }

    my $feature = new Bio::EnsEMBL::Feature (
      -dbID           => $id,
      -slice          => $slice,
      -start          => $hit->{'gstart'},
      -end            => $hit->{'gend'},
      -strand         => $hit->{'gori'},
      -analysis       => $analysis,
    );

     my %feat_info = (    
      btop_string    => $btop,
      coords         => $coords,
      target_strand  => $hit->{'tori'},
      ticket_name    => $ticket->ticket_name,
      colour         => $colour,
      db_type        => $db_type,
    );

    $extra{$id} = \%feat_info;
    push @features, $feature;
  }

  return (\@features,  \%extra);  
}

sub get_colour_scale {
  my $self = shift;use Carp qw(croak); croak 'TODO';
  my %pointer_defaults    = ();#EnsEMBL::Web::BlastConstants::KARYOTYPE_POINTER_DEFAULTS; #use blast_pointer_style
  my $defaults            = $pointer_defaults{'Blast'};
  my $gradient            = $defaults->[2];
  my @colour_scale        = $self->{'config'}->colourmap->build_linear_gradient(@$gradient);
  my $colours;


  my $i = 0;
  foreach my $colour (@colour_scale) {
    $colours->{$i} = $colour;
    $i = sprintf("%.1f", $i + 0.1);
  }
 
  return $colours;
}

sub highlight {
  my ($self, $f, $composite,$pix_per_bp, $h) = @_;
  my $highlight = $self->{'config'}->hub->param('h');
 
  return unless $highlight eq $f->dbID;

  $self->unshift( $self->Rect({ 
    'x'         => $composite->x() - 2/$pix_per_bp,
    'y'         => $composite->y() + 6, ## + makes it go down
    'width'     => ($composite->width() -1) + 4/$pix_per_bp,
    'height'    => $h + 4,
    'colour'    => 'highlight2',
    'absolutey' => 1,
  }));
}

sub render_normal {
  my $self = shift;

  my $dep             = @_ ? shift : ($self->my_config('dep') || 100);
     $dep = 0 if $self->my_config('nobump') or $self->my_config('strandbump');
  my $strand            = $self->strand;
  my $strand_flag       = $self->my_config('strand');
  my $length            = $self->{'container'}->length;
  my $pix_per_bp        = $self->scalex;
  my $slice_start       = $self->{'container'}->start -1;
  my $slice_end         = $self->{'container'}->end;    
  my ($font, $fontsize) = $self->get_font_details($self->my_config('font') || 'innertext');
  my $h                 = $self->my_config('height') || 8;
  my $gap               = $h < 2 ? 1 : 2;

  my ($features, $aln_info) = $self->features; 

  my $y_offset        = 0;
  my $features_bumped = 0;

  $self->_init_bump(undef, $dep);

  foreach my $f (@$features){

    my $start = $f->start;      
    my $end = $f->end; 
    my $invert = $f->strand == $aln_info->{$f->dbID}->{'target_strand'} ? undef : 1;

    if ($start < $slice_start ){$start = $slice_start;}
    if ($end > $slice_end) {$end  = $slice_end;}    

    my $bump_start = int($pix_per_bp * ($start - $slice_start < 1 ? 1 : $start - $slice_start)) -1;
    my $bump_end = int($pix_per_bp * ($end - $slice_start > $length ? $length : $end - $slice_start));

    my $row = 0;
    if ($dep > 0 ){
      $row = $self->bump_row($bump_start, $bump_end);
      
      if ($row > $dep){
        $features_bumped++;
        next;
      }
    }

    my $y_pos = $y_offset - $row * int($h + 5 + $gap) * $strand;

    my $btop        = $aln_info->{$f->dbID}->{'btop_string'};
    my $coords      = $aln_info->{$f->dbID}->{'coords'};
    my $ticket_name = $aln_info->{$f->dbID}->{'ticket_name'};
    my $colour      = $aln_info->{$f->dbID}->{'colour'};
    my $db_type     = $aln_info->{$f->dbID}->{'db_type'};

    my $composite = $self->Composite({
      x         => $start - $slice_start,
      y         => -8,
      width     => $end - $start,
      height    => $h + 9,
      title     => undef,
      href      => $self->href($ticket_name, $f->dbID),
    }); 

    if ($btop){ 
      $self->draw_btop_feature({
        composite       => $composite,
        feature         => $f,
        height          => $h,
        feature_colour  => $colour,
        scalex          => $pix_per_bp,
        btop            => $btop,
        coords          => $coords,
        seq_invert      => $invert,
        y_offset        => $y_pos,
      });
    } else {
      $self->draw_aln_coords({
        composite       => $composite,
        feature         => $f,
        height          => $h,
        feature_colour  => $colour,
        scalex          => $pix_per_bp,
        coords          => $coords,
        seq_invert      => $invert,
        y_offset        => $y_pos,

      });
    }

    $composite->border_colour($colour);

    $composite->y($composite->y + $y_pos);
    $self->push($composite);
    $self->highlight($f, $composite, $pix_per_bp, $h);

  }
}

sub href {
  my ($self, $ticket_name, $hit_id) = @_;
  return $self->_url({
    species => $self->species,
    action  => 'Blast',
    hid     => $hit_id,
    tk      => $ticket_name,
  });
}

sub draw_aln_coords {
  my ($self, $params) = @_;
  my ($composite, $f, $h) = map $params->{$_}, qw(composite feature height);
  my $pix_per_bp = $self->scalex;
  my $slice = $self->{'container'};
  my $length = $slice->length;
  my $slice_start = $slice->start;
  my $slice_end = $slice->end;
  my $match_colour = $params->{'feature_colour'};
  my $method = $self->{'config'}->hub->param('method');

  my $coords = $params->{'coords'};

  my ($first_exon_start, $last_exon_end, $exon_drawn, $previous_end);

  foreach my $block (@$coords) {
    my $s = lc $method =~/^tblastn/ ? $block->{'start'} : $block->start;
    my $e = lc $method =~/^tblastn/ ? $block->{'end'} : $block->end;
    my $start = $s - $slice_start;
    my $end   = $e - $slice_start;

    next if $start < 0 && $end < 0;
    next if $start > $slice_end;
    
    $start = 0 if $start < 0;
    $first_exon_start = $start if !$exon_drawn;
    $end = $slice_end if $end > $slice_end; 
    $last_exon_end = $end;

    my $block_length = $end - $start +1;    

    if ( $exon_drawn ){
      my $gap_start = $previous_end < 0 ? 0 : $previous_end;
      my $gap_width = $start - $previous_end;

      $composite->push($self->Rect({
        x         => $gap_start,
        y         => $params->{'y'} || 0,
        width     => $gap_width,
        height    => $h,
        bordercolour    => $match_colour,
      }));
    }

    $composite->push($self->Rect({
      x         => $start,
      y         => $params->{'y'} || 0,
      width     => $block_length,
      height    => $h,
      colour    => $match_colour,
    }));
    $exon_drawn = 1;
    $previous_end = $end;
  }
}
1;

package Bio::EnsEMBL::GlyphSet::blast_hit_btop;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Bio::EnsEMBL::GlyphSet);

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::Feature;

sub colour_key {return 'blast';}
sub title {}

sub features {
  my $self = shift;
  my $slice = $self->{'container'};
  my @features; 

  my $tools_object = $self->{'config'}->{'hub'}->{'_core_objects'}->{'tools'};
  return unless $tools_object;

  my $ticket = $tools_object->ticket;

  my @result_lines = @{$tools_object->get_all_hits_from_ticket_in_region($slice, $ticket->ticket_id)};
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
    my $colour              = $colours->{$identity};

    
    my $btop =  $hit->{'db_type'} =~/cdna/ ?  $tools_object->map_btop_to_genomic_coords($hit, $_->[0]) : $hit->{'aln'};


    if ($hit->{'gori'} ne '1' && $hit->{'db_type'}=~/latest/i){
      $btop = $tools_object->reverse_btop($btop);
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
    );

    $extra{$id} = \%feat_info;
    push @features, $feature;
  }

  return (\@features,  \%extra);  
}

sub get_colour_scale {
  my $self = shift;
  my %pointer_defaults    = EnsEMBL::Web::ToolsConstants::KARYOTYPE_POINTER_DEFAULTS;
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
    my $invert = $f->strand == -1 ? 1 : undef;

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

    my $composite = $self->Composite({
      x         => $start - $slice_start,
      y         => -8,
      width     => $end - $start,
      height    => $h + 9,
      title     => undef,
      href      => $self->href($ticket_name, $f->dbID),
    }); 

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

1;

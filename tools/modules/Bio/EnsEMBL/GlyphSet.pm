package Bio::EnsEMBL::GlyphSet;

use strict;

sub draw_btop_feature { 
  my ($self, $params) = @_;
  my ($composite, $f, $h) = map $params->{$_}, qw(composite feature height);
  my $pix_per_bp = $self->scalex;
  my $slice = $self->{'container'};
  my $length = $slice->length;
  my $slice_start = $slice->start;
  my $slice_end = $slice->end;

  my $seq   = $slice->seq;
  my $match_colour = $params->{'feature_colour'};
  my $mismatch_colour  = $self->{'config'}->colourmap->mix($match_colour, 'white', 0.6);  
  my($font, $fontsize) = $self->get_font_details( $self->can('fixed') ? 'fixed' : 'innertext' );
  my($tmp1, $tmp2, $font_w, $font_h) = $self->get_text_width(0, 'X', '', 'font' => $font, 'ptsize' => $fontsize);
  my $text_fits =  $font_w * $slice->length <= int($slice->length * $pix_per_bp);
  
  my $btop = $params->{'btop'};
  $btop =~s/(\d+)/:$1:/g;
  $btop =~s/^:|:$//g;
  my @btop_features = split (/:/, $btop);

  my $slice_start= $self->{'container'}->start;
  my $end = $f->end > $slice_end ? $slice_end : $f->end;
  $end = $end - $slice_start + 1; 

  my $seq_start = $f->start > $slice_start ? $f->start - $slice_start : 0;
  my $s1 = $f->start - $slice_start; 
  my $width = $end - $seq_start +1;

  $seq = substr($seq, $seq_start, $width); 
  my (%seq_diffs, @inserts);

  while (scalar @btop_features > 0 ){
    my $seq_index  = shift @btop_features;   
    my $diff_string = shift @btop_features; 
    my $diff_length = (length $diff_string) /2;
    my @diffs = split (//, $diff_string);

    my ($processed_diffs, $previous_state, $insert_count, $gap_count);
    my $count = 0;

    if (scalar @diffs > 2) {
      while (my $query_base = shift @diffs){
        my $target_base = shift @diffs;

        my $state = $target_base eq '-' ? 'insert' : 
                    $query_base eq '-' && $target_base ne 'N' ?'gap' :
                    ($query_base =~/[ACTG]/i && $target_base =~/[ACTG]/i) ? 'mismatch' : 'intron';

        my @diff = ($query_base, $target_base);   
        $insert_count++ if $state eq 'insert';
        $gap_count++ if $state eq 'gap';        

        if (!$previous_state){
          $processed_diffs->[0] = \@diff;
        } elsif ( $state eq $previous_state){
          my @temp = @{$processed_diffs->[$count]};
          push @temp,  @diff;
          $processed_diffs->[$count] = \@temp;
        } else {
          $count++;
          $processed_diffs->[$count] = \@diff;
        };
        $previous_state = $state;
      }
    } else {
      $insert_count++ if $diffs[1] eq '-';
      $processed_diffs->[0] = \@diffs;
    }

    
    my $e1 = $s1 + $seq_index;
    my $s2 = $e1;
    my $e2;
    my $end_of_block = $s1 + $seq_index + $diff_length - $insert_count; 

    unless ( ($s1 < 0 && $end_of_block < 0) || ($s1 > $length  && $end_of_block > $length) ){ 
      my $start = $s1;
      $start = $start < 0 ? 0 : $start;
      $e1 = $e1 > $length ? $length : $e1;
      $e1 = $e1 > $end ? $end : $e1;

      unless ($diff_string){  
        $composite->push($self->Rect({
          x         => $start,
          y         => $params->{'y'} || 0,
          width     => $e1 -$start,
          height    => $h,
          colour    => $match_colour,
        }));
        next;
      }

      unless ( $e1 < 0) {
      $composite->push($self->Rect({
          x         => $start,
          y         => $params->{'y'} || 0,
          width     => $e1 - $start,
          height    => $h,
          colour    => $match_colour,
        }));
      }

      foreach my $d (@{$processed_diffs}){
        my @differences = @{$d};  
        my $diff_length = scalar @differences; 
        $diff_length = $diff_length /2;
        my $e2 = $s2 + $diff_length;

        unless (($s2 < 0 && $e2 < 0) || ($s2 > $length  && $e2 > $length)) {
          $s2 = $s2 < 0 ? 0 : $s2;
          $e2 = $e2 > $length ? $length : $e2;

        # If mismatch 
          if ($differences[0] =~/[ACTG]/ && $differences[1] =~/[ACTG]/){  
            $composite->push($self->Rect({
              x         => $s2,
              y         => $params->{'y'} || 0,
              width     => $e2 - $s2,
              height    => $h,
              colour    => $mismatch_colour,
            }));

            my $i = $s2; 
            while (@differences){ 
              my $q = shift @differences; 
              my $h = shift @differences;
              my @temp = ($q, 'black');  
              $seq_diffs{$slice_start + $i} = \@temp;
              $i++;
            }        
          } elsif ($differences[0] eq '-') { # Gap in hsp
            $composite->push($self->Rect({
              x         => $s2,
              y         => $params->{'y'} || 0,
              width     => $e2 - $s2,
              height    => $h,
              bordercolour    => $match_colour,
            }));

            my $j = $e2 - $s2; 
            my $i = $s2;
            for ( $i;  $i < $j;  $i++){
              my @temp = (undef, undef);
              $seq_diffs{$i} = \@temp;          
            }
          } else { #Insert in hit
            my @evens = @differences[grep !($_ % 2), 0..$#differences];
            my $i_count = scalar @evens;
            my $insert_string = join '',  @evens;
            push @inserts, {
              'pos' => $s2,
              'title'   => "Insert: " .$insert_string
            };
            $e2 = $e2 - $i_count;
          }   
        }
        $s2 = $e2;
      }
    }

    $s1 = $s1 + $seq_index + $diff_length;
    $s1 -= $insert_count;    
  }

  # Add alignment seq if zoomed in
  if ($text_fits){ 
    my $i = 0;
    foreach my $base ( split //, $seq) {
      my $x = $seq_start + $i;
      my $pos = $slice_start + $seq_start + $i;
      my $colour = 'white';

      $base =~ tr/ACGTacgt/TGCAtgca/ if $params->{'seq_invert'};

      if ($seq_diffs{$pos}){ 
        $base = $seq_diffs{$pos}->[0];
        $colour = $seq_diffs{$pos}->[1]; 
      }

      $composite->push($self->Text({
        x         => $x, 
        y         => $params->{'y'} || 0,
        width     => 1,
        textwidth => 1,
        halign    => 'center',
        height    => $h,
        colour    => $colour,
        text      => $base,
        font      => $font,
        ptsize    => $fontsize,
      }));
      $i++;
    }
  }

  # Add insert markers
  foreach my $ins (@inserts){
    my $y = $params->{'y_offset'} || 0;
    $self->push($self->Triangle({
      mid_point     => [$ins->{'pos'}, $h + $y -8],
      width         => 10 / $pix_per_bp,
      height        => 4,
      colour        => 'black',
      direction     => 'down',
      title         => $ins->{'title'}
    }));
  }

}
1;

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet::BlastHit;

## Blast track for contigviewbottom

use strict;
use warnings;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::Feature;
use Bio::EnsEMBL::Mapper::Coordinate;

use EnsEMBL::Web::BlastConstants qw(BLAST_KARYOTYPE_POINTER);

use parent qw(EnsEMBL::Draw::GlyphSet);

sub label_overlay { return 1; }
sub fixed         { return 0; }
sub colour_key    { return 'blast'; }
sub title         { }

sub features {
  my $self    = shift;
  my $hub     = $self->{'config'}->hub;
  my $slice   = $self->{'container'};
  my $object  = $hub->core_object('Tools') or return;
     $object  = $object->get_sub_object('Blast');
  my $ticket  = $object->get_requested_ticket({'with_results' => 1}) or return;
  my ($job)   = grep($_->job_id == $self->my_config('job_id'), @{$ticket->job}) or return;
  my $method  = $object->parse_search_type($job->job_data->{'search_type'}, 'search_method');
  my $strand  = $self->strand;
  my @hits    = grep $strand eq $_->{'gori'}, @{$object->get_all_hits_in_slice_region($job, $slice, sub { ($a->{'score'} || 0) <=> ($b->{'score'} || 0) })};

  return unless @hits;

  my $analysis = Bio::EnsEMBL::Analysis->new(
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

  my (@features, %features_info);

  foreach my $hit (@hits) {

    my $result_id     = $hit->{'result_id'};
    my $coords        = $hit->{'g_coords'} || [];
    my $colour        = $self->get_colour($hit->{'pident'});
    my $slice_length  = $slice->length;
    my $source        = $hit->{'source'};

    my $btop;

    if ($slice_length < 10000 && ($method =~ /^blastn/i || $method =~ /^blat/i)) { # draw btop in this case

      $btop = $object->map_btop_to_genomic_coords($hit, $job);

    } else {

      if ($method =~ /tblastn/i || $source =~/latest/i) {
        if (@$coords) {
          $coords->[0]->start($hit->{'gstart'});
          $coords->[0]->end($hit->{'gend'});
        } else {
          push @$coords, Bio::EnsEMBL::Mapper::Coordinate->new($hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'});
        }
      }
    }

    push @features, Bio::EnsEMBL::Feature->new(
      -dbID     => $result_id,
      -slice    => $slice,
      -start    => $hit->{'gstart'},
      -end      => $hit->{'gend'},
      -strand   => $hit->{'gori'},
      -analysis => $analysis,
    );

    $features_info{$result_id} = {
      btop_string   => $btop,
      coords        => $coords,
      q_strand      => $hit->{'qori'},
      tl            => $hit->{'tl'},
      colour        => $colour,
      blast_type    => $method
    };
  }

  return (\@features, \%features_info);
}

sub render_normal {
  my $self                  = shift;
  my $dep                   = @_ ? shift : ($self->my_config('dep') || 100);
     $dep                   = 0 if $self->my_config('nobump') || $self->my_config('strandbump');
  my $strand                = $self->strand;
  my $strand_flag           = $self->my_config('strand');
  my $slice                 = $self->{'container'};
  my $length                = $slice->length;
  my $pix_per_bp            = $self->scalex;
  my $slice_start           = $slice->start - 1;
  my $slice_end             = $slice->end;
  my ($font, $fontsize)     = $self->get_font_details($self->my_config('font') || 'innertext');
  my $height                = $self->my_config('height') || 11;
  my $gap                   = $height < 2 ? 1 : 2;
  my @feats                 = $self->features;
  my $features              = $feats[0] || [];
  my $features_info         = $feats[1] || {};
  my $y_offset              = 0;
  my $features_bumped       = 0;

  $self->_init_bump(undef, $dep);

  return $self->my_config('main_blast') ? $self->no_track_on_strand : undef unless @$features;

  foreach my $feature (@$features) {

    my $db_id       = $feature->dbID;
    my $feat_info   = $features_info->{$db_id};
    my $method      = $feat_info->{'blast_type'};
    my $start       = $feature->start;
       $start       = $slice_start if $start < $slice_start;
    my $end         = $feature->end;
       $end         = $slice_end if $end > $slice_end;
    my $invert      = $feature->strand != $feat_info->{'q_strand'};
    my $bump_start  = int($pix_per_bp * ($start - $slice_start < 1 ? 1 : $start - $slice_start)) -1;
    my $bump_end    = int($pix_per_bp * ($end - $slice_start > $length ? $length : $end - $slice_start));

    my $row = 0;
    if ($dep > 0) {
      $row = $self->bump_row($bump_start, $bump_end);

      if ($row > $dep) {
        $features_bumped++;
        next;
      }
    }

    my $y_pos       = $y_offset - $row * int($height + 5 + $gap) * $strand;
    my $btop        = $feat_info->{'btop_string'};
    my $coords      = $feat_info->{'coords'};
    my $ticket_name = $feat_info->{'ticket_name'};
    my $colour      = $feat_info->{'colour'};

    my $composite   = $self->Composite({
      x               => $start - $slice_start,
      y               => -8,
      width           => $end - $start,
      height          => $height + 9,
      title           => undef,
      href            => $self->_url({
        species         => $self->species,
        type            => 'Tools',
        action          => 'BlastTrack',
        function        => '',
        tl              => $feat_info->{'tl'}
      })
    });

    if ($btop) {
      $self->draw_btop_feature({
        blast_method    => $method,
        composite       => $composite,
        feature         => $feature,
        height          => $height,
        feature_colour  => $colour,
        scalex          => $pix_per_bp,
        btop            => $btop,
        coords          => $coords,
        seq_invert      => $invert,
        y_offset        => $y_pos,
      });
    } else {
      $self->draw_aln_coords({
        blast_method    => $method,
        composite       => $composite,
        feature         => $feature,
        height          => $height,
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
    $self->highlight($feature, $composite, $pix_per_bp, $height);
  }
}

sub get_colour {
  my ($self, $percent) = @_;

  my $scale = $self->{'_colour_scale'} ||= [ $self->{'config'}->colourmap->build_linear_gradient(@{BLAST_KARYOTYPE_POINTER->{$self->my_config('main_blast') ? 'gradient' : 'gradient_others'}}) ];

  return $scale->[ sprintf '%.f', $percent * (scalar @$scale - 1) / 100 ];
}

sub highlight {
  my ($self, $feature, $composite, $pix_per_bp, $height) = @_;
  my $highlight = $self->{'config'}->hub->param('h');

  return unless ($highlight || '') eq $feature->dbID;

  $self->unshift( $self->Rect({
    'x'         => $composite->x() - 2/$pix_per_bp,
    'y'         => $composite->y() + 6, ## + makes it go down
    'width'     => ($composite->width() -1) + 4/$pix_per_bp,
    'height'    => $height + 4,
    'colour'    => 'highlight2',
    'absolutey' => 1,
  }));
}

sub draw_aln_coords {
  my ($self, $params) = @_;
  my $pix_per_bp      = $self->scalex;
  my $slice           = $self->{'container'};
  my $length          = $slice->length;
  my $slice_start     = $slice->start;
  my $slice_end       = $slice->end;
  my $composite       = $params->{'composite'};
  my $height          = $params->{'height'};
  my $match_colour    = $params->{'feature_colour'};
  my $method          = $params->{'blast_method'};
  my $coords          = $params->{'coords'};
  my %pattern         = $self->pattern;

  my ($first_exon_start, $last_exon_end, $exon_drawn, $previous_end);

  foreach my $block (@$coords) {
    my $start = $block->start - $slice_start;
    my $end   = $block->end   - $slice_start;

    next if $start < 0 && $end < 0;
    next if $start > $slice_end;

    $start            = 0 if $start < 0;
    $first_exon_start = $start if !$exon_drawn;
    $end              = $slice_end if $end > $slice_end;
    $last_exon_end    = $end;

    my $block_length  = $end - $start + 1;

    if ($exon_drawn) {
      my $gap_start = $previous_end < 0 ? 0 : $previous_end;
      my $gap_width = $start - $previous_end;

      $composite->push($self->Rect({
        x             => $gap_start,
        y             => $params->{'y'} || 0,
        width         => $gap_width,
        height        => $height,
        bordercolour  => $match_colour,
      }));
    }

    $composite->push($self->Rect({
      x         => $start,
      y         => $params->{'y'} || 0,
      width     => $block_length,
      height    => $height,
      colour    => $match_colour,
      %pattern
    }));
    $exon_drawn   = 1;
    $previous_end = $end;
  }
}

sub draw_btop_feature {
  my ($self, $params) = @_;
  my $composite       = $params->{'composite'};
  my $feature         = $params->{'feature'};
  my $height          = $params->{'height'};
  my $pix_per_bp      = $self->scalex;
  my $slice           = $self->{'container'};
  my $length          = $slice->length;
  my $slice_start     = $slice->start;
  my $slice_end       = $slice->end;
  my $seq             = $params->{'seq_invert'} ? reverse $slice->invert->seq : $slice->seq;

  my $match_colour      = $params->{'feature_colour'};
  my $mismatch_colour   = $self->{'config'}->colourmap->mix($match_colour, 'white', 0.9);
  my ($font, $fontsize) = $self->get_font_details( $self->fixed ? 'fixed' : 'innertext' );
  my ($tmp1, $tmp2, $font_w, $font_h) = $self->get_text_width(0, 'X', '', 'font' => $font, 'ptsize' => $fontsize);
  my $text_fits         = 0.8 * $font_w * $slice->length <= int($slice->length * $pix_per_bp);
  my %pattern           = $text_fits ? () : $self->pattern;

  my $btop = $params->{'btop'};
  $btop =~s/(\d+)/:$1:/g;
  $btop =~s/^:|:$//g;
  my @btop_features = split (/:/, $btop);

  my $end = $feature->end > $slice_end ? $slice_end : $feature->end;
  $end = $end - $slice_start + 1;

  my $seq_start = $feature->start > $slice_start ? $feature->start - $slice_start : 0;
  my $s1 = $feature->start - $slice_start;
  my $width = $end - $seq_start + 1;

  $seq = substr($seq, $seq_start, $width);
  my (%seq_diffs, @inserts);

  while (scalar @btop_features > 0) {
    my $seq_index   = shift @btop_features;
    my $diff_string = shift @btop_features || '';
    my $diff_length = (length $diff_string) /2;
    my @diffs = split (//, $diff_string);

    my ($processed_diffs, $previous_state);
    my $count         = 0;
    my $insert_count  = 0;
    my $gap_count     = 0;

    if (scalar @diffs > 2) {
      while (my $query_base = shift @diffs) {
        my $target_base = shift @diffs;

        my $state = $target_base eq '-' && $query_base ne '-' ? 'insert' :
                    $query_base eq '-' && $target_base ne '-' ?'gap' :
                    ($query_base =~/[ACTG]/i && $target_base =~/[ACTG]/i) ? 'mismatch' : 'intron';

        my @diff = ($query_base, $target_base);
        $insert_count++ if $state eq 'insert';
        $gap_count++    if $state eq 'gap';

        if (!$previous_state) {
          $processed_diffs->[0] = \@diff;
        } elsif ($state eq $previous_state) {
          my @temp = @{$processed_diffs->[$count]};
          push @temp, @diff;
          $processed_diffs->[$count] = \@temp;
        } else {
          $count++;
          $processed_diffs->[$count] = \@diff;
        };
        $previous_state = $state;
      }
    } else {
      $insert_count++ if @diffs > 1 && $diffs[1] eq '-' && $diffs[0] ne '-';
      $processed_diffs->[0] = \@diffs;
    }


    my $e1 = $s1 + $seq_index;
    my $s2 = $e1;
    my $e2;
    my $end_of_block = $s1 + $seq_index + $diff_length - $insert_count;

    unless ( ($s1 < 0 && $end_of_block < 1) || ($s1 > $length  && $end_of_block > $length) ){
      my $start = $s1;
      $start = $start < 0 ? 0 : $start;
      $e1 = $e1 > $length ? $length : $e1;
      $e1 = $e1 > $end ? $end : $e1;

      if ($e1 >= 0 || !$diff_string) {
        $composite->push($self->Rect({
          x         => $start,
          y         => $params->{'y'} || 0,
          width     => $e1 - $start,
          height    => $height,
          colour    => $match_colour,
          %pattern
        }));

        next unless $diff_string;
      }

      foreach my $d (@{$processed_diffs}) {
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
              height    => $height,
              colour    => $mismatch_colour,
              %pattern
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
              x             => $s2,
              y             => $params->{'y'} || 0,
              width         => $e2 - $s2,
              height        => $height,
              bordercolour  => $match_colour,
              %pattern
            }));

            my $j = $e2 - $s2;
            for ( my $i = $s2;  $i < $j;  $i++){
              my @temp = (undef, undef);
              $seq_diffs{$i} = \@temp;
            }
          } else { #Insert in hit
            my @evens = @differences[grep !($_ % 2), 0..$#differences];
            my $i_count = scalar @evens;
            my $insert_string = join '',  @evens;
            push @inserts, {
              'pos'   => $s2,
              'title' => "Insert: " .$insert_string
            };
            $e2 = $e2 - $i_count;
          }
        }
        $s2 = $e2;
      }
    }
    last if $s2 > $length;
    $s1 = $s1 + $seq_index + $diff_length;
    $s1 -= $insert_count;
  }

  # Add alignment seq if zoomed in
  if ($text_fits) {
    my $i = 0;
    foreach my $base ( split //, $seq) {
      my $x = $seq_start + $i;
      my $pos = $slice_start + $seq_start + $i;
      my $colour = 'white';
      if ($seq_diffs{$pos}){
        $base = $seq_diffs{$pos}->[0];
        $colour = $seq_diffs{$pos}->[1];
      }

      $composite->push($self->Text({
        x         => $x,
        y         => ($params->{'y'} || 0) - 1,
        width     => 1,
        textwidth => $font_w,
        halign    => 'center',
        height    => $height,
        colour    => $colour,
        text      => $base,
        font      => $font,
        ptsize    => $fontsize,
      }));
      $i++;
    }
  }

  # Add insert markers
  foreach my $ins (@inserts) {
    my $y = $params->{'y_offset'} || 0;
    $self->push($self->Triangle({
      mid_point     => [$ins->{'pos'}, $height + $y - 12],
      width         => 8 / $pix_per_bp,
      height        => 4,
      colour        => 'black',
      direction     => 'down',
      title         => $ins->{'title'}
    }));
  }

}

sub pattern {
  my @pattern = split /\|/, $_[0]->{'my_config'}->data->{'pattern'};
  return ('pattern' => $pattern[0], 'patterncolour' => $pattern[1]);
}

1;

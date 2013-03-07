# $Id$

package EnsEMBL::Web::Component::TextSequence;

use strict;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->{'key_types'}  = [qw(codons conservation population resequencing align_change)];
  $self->{'key_params'} = [qw(gene_name gene_exon_type alignment_numbering match_display hsp_display)];

  return $self;
}


# Used by Compara_Alignments, Gene::GeneSeq and Location::SequenceAlignment
sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $hub = $self->hub;
  my $sequence = [];
  my @markup;

  $self->set_variation_filter($config) if $config->{'snp_display'};

  $config->{'length'} ||= $slices->[0]{'slice'}->length;

  foreach my $sl (@$slices) {
    my $mk  = {};
    my $seq = uc($sl->{'seq'} || $sl->{'slice'}->seq(1));

    $self->set_sequence($config, $sequence, $mk, $seq, $sl->{'name'});
    $self->set_alignments($config, $sl, $mk, $seq)      if $config->{'align'}; # Markup region changes and inserts on comparisons
    $self->set_variations($config, $sl, $mk, $sequence) if $config->{'snp_display'};
    $self->set_exons($config, $sl, $mk)                 if $config->{'exon_display'};
    $self->set_codons( $config, $sl, $mk)                         if $config->{'codons_display'};
    $self->set_hsps($config, $sl, $mk)                  if $config->{'hsp_display'};
  
    push @markup, $mk;
  }

  return ($sequence, \@markup);

}

sub set_exons {
  my ($self, $config, $slice_data, $markup) = @_;
  return if $slice_data->{'no_markup'};
  my $slice    = $slice_data->{'slice'};
  my $exontype = $config->{'exon_display'};
  my ($slice_start, $slice_end, $slice_length, $slice_strand) = map $slice->$_, qw(start end length strand);
  my @exons;

  if ($exontype eq 'Ab-initio') {
    @exons = grep { $_->seq_region_start <= $slice_end && $_->seq_region_end >= $slice_start } map @{$_->get_all_Exons}, @{$slice->get_all_PredictionTranscripts};
  } elsif ($exontype eq 'vega' || $exontype eq 'est') {
    @exons = map @{$_->get_all_Exons}, @{$slice->get_all_Genes('', $exontype)};
  } else {
    @exons = map @{$_->get_all_Exons}, @{$slice->get_all_Genes};
  }
 
  # Values of parameter should not be fwd and rev - this is confusing.
  if ($config->{'exon_ori'} eq 'fwd') {
    @exons = grep { $_->strand > 0 } @exons; # Only exons in same orientation 
  } elsif ($config->{'exon_ori'} eq 'rev') {
    @exons = grep { $_->strand < 0 } @exons; # Only exons in opposite orientation
  }
 
  my @all_exons = map [ $config->{'comparison'} ? 'compara' : 'other', $_ ], @exons;

  if ($config->{'exon_features'}) {
    push @all_exons, [ 'gene', $_ ] for @{$config->{'exon_features'}};

    if ($config->{'exon_features'} && $config->{'exon_features'}->[0] && $config->{'exon_features'}->[0]->isa('Bio::EnsEMBL::Exon')) {
      $config->{'gene_exon_type'} = 'exons';
    } else {
      $config->{'gene_exon_type'} = 'features';
    }
  }
 
  foreach (@all_exons) {
    my $type = $_->[0];
    my $exon = $_->[1];

    next unless $exon->seq_region_start && $exon->seq_region_end;

    my @exon_coords;

    if ($config->{'mapper'}){
      my @temp =  $config->{'mapper'}->map_coordinates($slice->seq_region_name, $exon->seq_region_start, $exon->seq_region_end, $slice_strand, 'ref_slice');
      foreach my $mapped_coords ( @temp){
        my $start = $mapped_coords->start -1;
        my $end   = $mapped_coords->end -1; 
        my $id    = $exon->can('stable_id') ? $exon->stable_id : '';

        push @exon_coords, [$start, $end, $id];
      }
    } else {
      my $start = $exon->start - ($type eq 'gene' ? $slice_start : 1);
      my $end   = $exon->end   - ($type eq 'gene' ? $slice_start : 1);
      my $id    = $exon->can('stable_id') ? $exon->stable_id : '';
      push @exon_coords, [$start, $end, $id];
    }

      
    foreach (@exon_coords) {
      my ($start, $end, $id) = @{$_};

      ($start, $end) = ($slice_length - $end - 1, $slice_length - $start - 1) if $type eq 'gene' && $slice_strand < 0 && $exon->strand < 0;

      next if $end < 0 || $start >= $slice_length;


      $start = 0 if $start < 0;
      $end   = $slice_length - 1 if $end >= $slice_length;

      for ($start..$end) {
        push @{$markup->{'exons'}{$_}{'type'}}, $type;
        $markup->{'exons'}{$_}{'id'} .= ($markup->{'exons'}{$_}{'id'} ? "\n" : '') . $id unless $markup->{'exons'}{$_}{'id'} =~ /$id/;
      }
    }
  }
}


sub set_codons {
  my ($self, $config, $slice_data, $markup) = @_;
  return if $slice_data->{'no_markup'};

  my $slice       = $slice_data->{'slice'};
  my @transcripts = map @{$_->get_all_Transcripts}, @{$slice->get_all_Genes};
  my ($slice_start, $slice_length) = map $slice->$_, qw(start length);
  
  if ($slice->isa('Bio::EnsEMBL::Compara::AlignSlice::Slice')) {
    foreach my $t (grep { $_->coding_region_start < $slice_length && $_->coding_region_end > 0 } @transcripts) {
      next unless defined $t->translation;

      my @codons;

      # FIXME: all_end_codon_mappings sometimes returns $_ as undefined for small subslices. This eval stops the error, but the codon will still be missing.
      # Awaiting a fix from the compara team.
      eval {
        push @codons, map {{ start => $_->start, end => $_->end, label => 'START' }} @{$t->translation->all_start_codon_mappings || []}; # START codons
        push @codons, map {{ start => $_->start, end => $_->end, label => 'STOP'  }} @{$t->translation->all_end_codon_mappings   || []}; # STOP codons
      };

      my $id = $t->stable_id;
     
      foreach my $c (@codons) {
        my ($start, $end) = ($c->{'start'}, $c->{'end'});
        
        # FIXME: Temporary hack until compara team can sort this out
        $start = $start - 2 * ($slice_start - 1);
        $end   = $end   - 2 * ($slice_start - 1);

        next if $end < 1 || $start > $slice_length;

        $start = 1 unless $start > 0;
        $end   = $slice_length unless $end < $slice_length;

        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . "$c->{'label'}($id)" for $start-1..$end-1;
      }
    } 
  } else { # Normal Slice
    foreach my $t (grep { $_->coding_region_start < $slice_length && $_->coding_region_end > 0 } @transcripts) {
      my ($start, $stop, $id, $strand) = ($t->coding_region_start, $t->coding_region_end, $t->stable_id, $slice->strand);

      if ($config->{'mapper'}){
        my @mapped_coords = $config->{'mapper'}->map_coordinates($slice->seq_region_name, $t->seq_region_start, $t->seq_region_end, $strand, 'ref_slice');

        $start = $mapped_coords[0]->start;
        $stop   = $mapped_coords[-1]->end;
      }

      # START codons
      if ($start >= 1) {
        my $label = ($strand == 1 ? 'START' : 'STOP') . "($id)";
        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . $label for $start-1..$start+1;
      }

      # STOP codons
      if ($stop <= $slice_length) {
        my $label = ($strand == 1 ? 'STOP' : 'START') . "($id)";
        $markup->{'codons'}{$_}{'label'} .= ($markup->{'codons'}{$_}{'label'} ? "\n" : '') . $label for $stop-3..$stop-1;
      }
    }
  }
}

sub set_hsps {
  my ($self, $config, $slice_data, $markup) = @_;
  my @hsps;
  my $page_action = $self->hub->action;
  my $slice_type = $page_action =~/Query/  ? 'q' : 'g'; 
  my $slice = $slice_data->{'slice'};
  my $serialised_analysis = $self->object->ticket->analysis->object;
  my $analysis_object = $self->object->deserialise($serialised_analysis);
  my @temp = values %{$analysis_object->{'_database'}};
  my $db_type = $temp[0]->{'type'};

  my ($slice_start, $slice_end, $slice_length) = ($slice->start, $slice->end, $slice->length); 

  if ($config->{'hsp_display'} eq 'all'){
    if ($slice_type eq 'g'){
      @hsps = @{$self->object->get_all_hits_from_ticket_in_region($slice)};
    } else {
      my @results = @{$self->object->ticket->result};
      foreach (@results){
        my $frozen_gzipped_hit = $_->result;
        my $hit = $self->object->deserialise($frozen_gzipped_hit);
        push @hsps, [$_->result_id, $hit];
      }
    }
  } elsif ($config->{'hsp_display'} eq 'sel'){
    my $genomic_hit = $self->object->fetch_blast_hit_by_id($self->hub->param('res'));
    push @hsps, [ $self->hub->param('res'), $genomic_hit];
  }

  foreach (@hsps){
    my $id  = $_->[0];
    my $hsp = $_->[1];
            
    # Take requested orientation into account
    my $ori = $self->hub->param('orientation');
    my $g_ori = $hsp->{'gori'};
     my $invert_flag = $ori eq 'fa' && $g_ori eq '-1' ? 1
                      : $ori eq 'fc' && $slice->strand eq '-1' ? 1
                      : $ori eq 'rc' && $slice->strand eq '-1' ? 1
                      : undef;


    if ($db_type !~/LATEST/ && $slice_type eq 'g'){
      my @coords = @{$hsp->{'g_coords'}};
 
      foreach (@coords){
        my $start = $_->{'start'} - $slice_start;
        my $end = $_->{'end'} - $slice_start; 
       
        if ($invert_flag){ 
          $end = $slice_end - $_->{'start'};
          $start =  $slice_end - $_->{'end'};
        }

        $start = 0 if $start < 0;
        $end   = $slice_length - 1 if $end >= $slice_length;
        my $type = $id eq $self->hub->param('res') ? 'sel' : 'other';

        for ($start..$end){
          push @{$markup->{'hsps'}->{$_}{'type'}}, $type;
        }
      }
    } else { 
      my $start = $hsp->{$slice_type. 'start'} - $slice_start;
      my $end = $hsp->{ $slice_type. 'end'} - $slice_start;

      if ($invert_flag){  
        $start = $slice_end - $hsp->{$slice_type .'start'};
        $end =  $slice_end - $hsp->{$slice_type . 'end'};
      }
      if ($start > $end ){
        my $temp = $start;
        $start = $end;  
        $end = $temp;
      }

      $start = 0 if $start < 0;
      $end   = $slice_length - 1 if $end >= $slice_length;
      my $type = $id eq $self->hub->param('res') ? 'sel' : 'other';

      for ($start..$end){
        push @{$markup->{'hsps'}->{$_}{'type'}}, $type;
      }
    }
  } 
}

sub markup_hsp {
  my $self = shift;
  my ($sequence, $markup, $config) = @_;
  my (%hsp_types, $hsp, $type, $seq);
  my $i = 0;

  my $class = {
    'sel' => 'h0',
    'other' => 'h1',
  };

  foreach my $data (@$markup) {
    $seq = $sequence->[$i];
    
    foreach ( sort { $a <=> $b } keys %{$data->{'hsps'}}) {
      $hsp = $data->{'hsps'}->{$_};  
      foreach $type (sort @{$hsp->{'type'}}) {
        $seq->[$_]->{'class'} = "$class->{$type} " unless $seq->[$_]->{'class'} =~ /\b$class->{$type}\b/;
        $hsp_types{$type} = 1;
      }
    }
   
    $i++;
  }

  $config->{'key'}->{'hsp'}->{$_} = 1 for keys %hsp_types
}

sub markup_blast_line_numbers {
  my ($self, $sequence, $config) = @_;
  
  # Keep track of which element of $sequence we are looking at
  my $n = 0;

  foreach my $sl (@{$config->{'slices'}}) {
    my $slice       = $sl->{'slice'};
    my $seq         = $sequence->[$n];
    my @numbering;

    if (!$slice) {
      @numbering = ({});
    } elsif ($config->{'line_numbering'} eq 'slice') {
      # Get the data for the slice
      my $ostrand     = $slice->strand;
      my $slice_start = $slice->start;
      my $slice_end   = $slice->end;
        
      @numbering = ({ 
        dir   => $ostrand,
        start => $ostrand > 0 ? $slice_start : $slice_end,
        end   => $ostrand > 0 ? $slice_end   : $slice_start,
        label => $slice->seq_region_name . ':'
      });
      
    } else {
      # Line numbers are relative to the sequence (start at 1)
      @numbering = ({
        dir   => 1,
        start => $config->{'sub_slice_start'} || 1,
        end   => $config->{'sub_slice_end'}   || $config->{'length'},
        label => ''
      });
   } 

    my $data = shift @numbering;
    my $s = 1;
    my $e = $config->{'display_width'}; 
    my $row_start = $data->{'start'};
    my $loop_end = $config->{'length'} + $config->{'display_width'};
    my ($start, $end);
    my $gap_count = 0;

    my $sl_seq_region_name = $slice->name;              
    my @seq_region_data = split (/:/, $sl_seq_region_name);
    my $region = $seq_region_data[-4];

    while ($e < $loop_end) {
      my $shift = 0; # To check if we've got a new element from @numbering
      $start = '';
      $end = '';

      my $sequence = $sl->{'seq'} || $slice->seq;
      my $segment = substr $sequence, $s -1, $config->{'display_width'};
      my $seg_length = length $segment;
    

      if ( $config->{'line_numbering'} eq 'sequence' || $sl->{'no_markup'}){
        my $gaps = ($segment =~tr/-//);
        $gap_count += $gaps; 
        $start = $s;
        if ( $config->{'line_numbering'} eq 'slice' && $start == 1 ){ 
          $start = $slice->start; 
          $s = $start; 
        } 
        $end = $s + $config->{'display_width'} -1  - $gaps;
        if ( $config->{'line_numbering'} eq 'slice' && $end > $slice->end){ $end = $slice->end - $gap_count; }
        elsif ( $config->{'line_numbering'} eq 'sequence' && $end > $slice->length ){ $end = $slice->length; }
        $s = $end + 1;
        $e += $config->{'display_width'}; 

      } else { #  We have the hit sequence, map alignment coords back to genomic

        my ($cs, $ce);
        my $start_flag = 0;
        my $end_flag = 0;
        my $index = 0;
        my @bases = split('', $segment);

        while ($start_flag < 1){          
          my $base = shift @bases; 
          if ($base ne '-') { 
            $cs = $s + $index;
            $start_flag = 1; 
          } 
          $index++;
        }

        $index = 0;

        while ($end_flag < 1){  
          my $base = unshift @bases;
          if ($base ne '-') { 
            $ce = $e - $index;
            $end_flag = 1;
          }
          $index++;
        }
       
        if ($config->{'mapper'}){ 
          my ($mapped_coords) =$config->{'mapper'}->map_coordinates('mapped_slice', $cs, $ce, 1, 'mapped_slice');
          $start =  $mapped_coords->start;
          $end =  $mapped_coords->end;            
        } else {
          $start = $cs;
          $end = $ce;
        }

        $s = $e +1;
        $e  += $config->{'display_width'};
      }

      my $label = '';

      push @{$config->{'line_numbers'}{$n}}, { start => $start, end => $end || undef, label => $label } unless $sl->{'no_numbers'};
    }
    $n++;
  }
}


sub class_to_style {
  my $self = shift;

  if (!$self->{'class_to_style'}) {
    my $hub          = $self->hub;
    my $colourmap    = $hub->colourmap;
    my $species_defs = $hub->species_defs;
    my $styles       = $species_defs->colour('sequence_markup');
    my $var_styles   = $species_defs->colour('variation');
    my $i            = 1;

    my %class_to_style = (
      con  => [ $i++, { 'background-color' => "#$styles->{'SEQ_CONSERVATION'}->{'default'}" } ],
      dif  => [ $i++, { 'background-color' => "#$styles->{'SEQ_DIFFERENCE'}->{'default'}" } ],
      res  => [ $i++, { 'color' => "#$styles->{'SEQ_RESEQEUNCING'}->{'default'}" } ],
      e0   => [ $i++, { 'color' => "#$styles->{'SEQ_EXON0'}->{'default'}" } ],
      e1   => [ $i++, { 'color' => "#$styles->{'SEQ_EXON1'}->{'default'}" } ],
      e2   => [ $i++, { 'color' => "#$styles->{'SEQ_EXON2'}->{'default'}" } ],
      eu   => [ $i++, { 'color' => "#$styles->{'SEQ_EXONUTR'}->{'default'}" } ],
      ef   => [ $i++, { 'color' => "#$styles->{'SEQ_EXONFLANK'}->{'default'}" } ],
      eo   => [ $i++, { 'background-color' => "#$styles->{'SEQ_EXONOTHER'}->{'default'}" } ],
      eg   => [ $i++, { 'color' => "#$styles->{'SEQ_EXONGENE'}->{'default'}", 'font-weight' => "bold" } ],
      c0   => [ $i++, { 'background-color' => "#$styles->{'SEQ_CODONC0'}->{'default'}" } ],
      c1   => [ $i++, { 'background-color' => "#$styles->{'SEQ_CODONC1'}->{'default'}" } ],
      cu   => [ $i++, { 'background-color' => "#$styles->{'SEQ_CODONUTR'}->{'default'}" } ],
      co   => [ $i++, { 'background-color' => "#$styles->{'SEQ_CODON'}->{'default'}" } ],
      aa   => [ $i++, { 'color' => "#$styles->{'SEQ_AMINOACID'}->{'default'}" } ],
      end  => [ $i++, { 'background-color' => "#$styles->{'SEQ_REGION_CHANGE'}->{'default'}", 'color' => "#$styles->{'SEQ_REGION_CHANGE'}->{'label'}" } ],
      bold => [ $i++, { 'font-weight' => 'bold' } ],
      failed => [ $i++, { 'background-color' => "#$styles->{'SEQ_FAILED'}->{'default'}" } ],
      h0    => [ $i++, {'font-weight' => 'bold', 'color' => "#$styles->{'SEQ_HSP0'}->{'default'}"}],
      h1    => [ $i++, {'font-weight' => 'bold', 'color' => "#$styles->{'SEQ_HSP1'}->{'default'}"}],
    );

    foreach (keys %$var_styles) {
      my $style = { 'background-color' => $colourmap->hex_by_name($var_styles->{$_}->{'default'}) };

      $style->{'color'} = $colourmap->hex_by_name($var_styles->{$_}->{'label'}) if $var_styles->{$_}->{'label'};

      $class_to_style{$_} = [ $i++, $style ];
    }
   
    $class_to_style{'var'} = [ $i++, { 'color' => "#$styles->{'SEQ_MAIN_SNP'}->{'default'}" } ];

    $self->{'class_to_style'} = \%class_to_style;
  }

  return $self->{'class_to_style'};
}

sub content_key {
  my $self   = shift;
  my $config = shift || {};
  my $hub    = $self->hub;

  $config->{'site_type'} = ucfirst(lc $hub->species_defs->ENSEMBL_SITETYPE) || 'Ensembl';

  for (@{$self->{'key_params'}}, qw(exon_display population_filter min_frequency consequence_filter)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }

  $config->{'key'}->{$_} = $hub->param($_) for @{$self->{'key_types'}};

  for my $p (grep $hub->param($_), qw(exons variations)) {
    $config->{'key'}->{$p}->{$_} = 1 for $hub->param($p);
  }

  return $self->get_key($config);
}

sub get_key {
  my ($self, $config, $k) = @_;

  my $hub            = $self->hub;
  my $class_to_style = $self->class_to_style;
  my $var_styles     = $hub->species_defs->colour('variation');
  my $image_config   = $hub->get_imageconfig('text_seq_legend');

  my $exon_type;
     $exon_type = $config->{'exon_display'} unless $config->{'exon_display'} eq 'selected';
     $exon_type = 'All' if $exon_type eq 'core' || !$exon_type;
     $exon_type = ucfirst $exon_type;

  my %key = (
    utr          => { class => 'cu',  text => 'UTR'                          },
    conservation => { class => 'con', text => 'Conserved regions'            },
    difference   => { class => 'dif', text => 'Differs from primary species' },
    align_change => { class => 'end', text => 'Start/end of aligned region'  },
    codons       => {
      co => { class => 'co', text => 'START/STOP codons'  },
      c0 => { class => 'c0', text => 'Alternating codons' },
      c1 => { class => 'c1', text => 'Alternating codons' },
    },
    exons       => {
      exon0   => { class => 'e0', text => 'Alternating exons'                                  },
      exon1   => { class => 'e1', text => 'Alternating exons'                                  },
      exon2   => { class => 'e2', text => 'Residue overlap splice site'                        },
      gene    => { class => 'eg', text => "$config->{'gene_name'} $config->{'gene_exon_type'}" },
      other   => { class => 'eo', text => "$exon_type exons"                                   },
      compara => { class => 'e2', text => "$exon_type exons"                                   }
    },
    hsp => {
      sel   => { class => 'h0', text => 'Location of selected alignment'},
      other => { class => 'h1', text => 'Location of other alignments'}
    }
  );

  %key = (%key, %$k) if $k;

  foreach my $type (keys %key) {
    if ($key{$type}{'class'}) {
      my $style = $class_to_style->{$key{$type}{'class'}}->[1];
      $key{$type}{'default'} = $style->{'background-color'};
      $key{$type}{'label'}   = $style->{'color'};
    } else {
      foreach (values %{$key{$type}}) {
        my $style = $class_to_style->{$_->{'class'}}->[1];

        $_->{'default'} = $style->{'background-color'};
        $_->{'label'}   = $style->{'color'};
      }
    }
  }
 
  $key{'variations'}{$_} = $var_styles->{$_} for keys %$var_styles;

  foreach my $type (keys %{$config->{'key'}}) {
    if (ref $config->{'key'}->{$type} eq 'HASH') {
      $image_config->{'legend'}->{$type}->{$_} = $key{$type}{$_} for grep $config->{'key'}->{$type}->{$_}, keys %{$config->{'key'}->{$type}};
    } elsif ($config->{'key'}->{$type}) {
      $image_config->{'legend'}->{$type} = $key{$type};
    }
  }
 
  $image_config->image_width(650);

  my $key_html;
     $key_html .= "<li>Displaying variations for $config->{'population_filter'} with a minimum frequency of $config->{'min_frequency'}</li>"             if $config->{'population_filter'};
     $key_html .= '<li>Variations are filtered by consequence type</li>',                                                                                if $config->{'consequence_filter'};
     $key_html .= '<li>Conserved regions are where >50&#37; of bases in alignments match</li>'                                                           if $config->{'key'}->{'conservation'};
     $key_html .= '<li><code>~&nbsp;&nbsp;</code>No resequencing coverage at this position</li>'                                                         if $config->{'resequencing'};
     $key_html  = "<ul>$key_html</ul>" if $key_html;

  return '<h4>Key</h4>' . $self->new_image(new EnsEMBL::Web::Fake({}), $image_config)->render . $key_html;
}


1;

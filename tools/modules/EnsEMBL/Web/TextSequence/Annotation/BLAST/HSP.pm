package EnsEMBL::Web::TextSequence::Annotation::BLAST::HSP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::TextSequence::Annotation);

sub annotate {
  my ($self, $config, $slice_data, $markup, $seq,$hub) = @_; 

  my $this_hit      = $config->{'hit'};
  my $job           = $config->{'job'};
  my $object        = $config->{'object'};
  my $slice_type    = $config->{'slice_type'};
  my $slice         = $slice_data->{'slice'};
  return unless $slice;
  my $source_type   = $job->job_data->{'source'};
  my $slice_start   = $slice->start;
  my $slice_end     = $slice->end;
  my $slice_length  = $slice->length;
  my $ori           = $config->{'orientation'} || ''; # TODO provide a default value to this somewhere!
  my $hits          = []; 

  if ($config->{'hsp_display'} eq 'all') {
    $hits = $slice_type eq 'g' ? $object->get_all_hits_in_slice_region($job, $slice) : $object->get_all_hits($job);
  } elsif ($config->{'hsp_display'} eq 'sel') {
    $hits = [ $this_hit ];
  }

  foreach my $hit (@$hits) {
    my $type        = $hit->{'result_id'} == $this_hit->{'result_id'} ? 'sel' : 'other';
    my $g_ori       = $hit->{'gori'};
    my @coords      = $source_type !~ /LATEST/ && $slice_type eq 'g' ? @{$hit->{'g_coords'}} : { start => $hit->{$slice_type . 'start'}, end => $hit->{$slice_type . 'end'} }; 
    my $invert_flag = $ori eq 'fa' && $g_ori eq '-1' ? 1 
                    : $ori eq 'fc' && $slice->strand eq '-1' ? 1 
                    : $ori eq 'rc' && $slice->strand eq '-1' ? 1 
                    : undef;

    foreach (@coords) {
      my $start = $_->{'start'} - $slice_start;
      my $end   = $_->{'end'}   - $slice_start;

      if ($invert_flag) {
        $start = $slice_end - $_->{'start'};
        $end   = $slice_end - $_->{'end'};
      }   

      ($start, $end) = ($end, $start) if $start > $end;
      $start = 0                      if $start < 0;
      $end   = $slice_length - 1      if $end >= $slice_length;

      push @{$markup->{'hsps'}{$_}{'type'}}, $type for $start..$end;
    }   
  }
}

1;

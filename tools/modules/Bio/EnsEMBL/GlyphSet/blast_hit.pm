package Bio::EnsEMBL::GlyphSet::blast_hit;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Bio::EnsEMBL::GlyphSet::_simple);

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::Feature;

sub colour_key {return 'blast';}
sub title {return 'test';}

sub features {
  my $self = shift;
  my $slice = $self->{'container'};
  my @features; 

  my $tools_object = $self->{'config'}->{'hub'}->{'_core_objects'}->{'tools'};
  return unless $tools_object;

  my $ticket = $tools_object->ticket;
  my @result_lines = @{$ticket->result};

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

  
  foreach my $res_line (@result_lines){

    my $result= $res_line->result;
    my $hit = $tools_object->deserialise($result);
    my $offset = $slice->start - 1;
    my $id = $res_line->result_id;
    my $coords = $hit->{'coords'} || undef;

    my $feature = new Bio::EnsEMBL::Feature (
      -dbID           => $id,
      -slice          => $slice,
      -start          => $hit->{'gstart'} - $offset,
      -end            => $hit->{'gend'} - $offset,
      -strand         => $hit->{'gori'},
      -analysis       => $analysis,
      -btop_string    => $hit->{'aln'},
      -coords         => $coords
    );

#    my $feature = new Bio::EnsEMBL::DnaDnaAlignFeature (
#      -slice        => $slice
#      -start        => $hit->{'tstart'} - $slice->start,
#      -end          => $hit->{'tend'} - $slice->start,
#      -strand       => $hit->{'tori'},
#      -hseqname     =>
#      -hstart       =>
#      -analysis     =>  $analysis,
#      -cigar_string =>
#    );

    push @features, $feature;
  }

  return \@features;  
}

sub highlight {
  my ($self, $f, $composite,$pix_per_bp, $h) = @_;
  my $highlight = $self->{'config'}->hub->param('h');

  return unless $highlight eq $f->dbID;

  $self->unshift( $self->Rect({ 
    'x'         => $composite->x() - 2/$pix_per_bp,
    'y'         => $composite->y() -2, ## + makes it go down
    'width'     => $composite->width() + 4/$pix_per_bp,
    'height'    => $h + 4,
    'colour'    => 'black',
    'absolutey' => 1,
  }));
}


1;

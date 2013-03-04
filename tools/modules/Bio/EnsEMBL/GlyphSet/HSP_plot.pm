package Bio::EnsEMBL::GlyphSet::HSP_plot;

use strict;

use Sanger::Graphics::Bump;
use EnsEMBL::Web::ToolsConstants;

use base qw(Bio::EnsEMBL::GlyphSet);


sub _init {
  my ($self)        = @_;
  my $container     = $self->{'container'};
  my $config        = $self->{'config'};
  my $mode          = ( $self->my_config('mode') || 
                        "byhit" );

  my $colours       = $self->get_colour_scale;
  my $opts = 
    {
     'pix_per_bp'    => $config->transform->{'scalex'},
     'bitmap_length' => int($container->length() * 
                            $config->transform->{'scalex'}),
     'id'            => $container->name,
     'db'            => $container->{'database'},
     'dep'           => ( $self->my_config('dep') || 10 ),
     'bitmap'        => [],
     'tally'         => {},
    };

  #########
  # track hsps for '<a name' links inside hits
  #
  #for my $hit (keys %{$container->{'hits'}}) {
  my @all_hsps = ();
  my $ori = $self->strand;
  foreach my $hsp( $container->hsps ){
    my $qori = $hsp->{'q_ori'} || 1;
    my $hori = $hsp->{'g_ori'}   || 1;
    if( $qori * $hori != $ori ){next}
    push( @all_hsps, $hsp );
  }

  map{ $self->hsp($_, $opts, $colours) }
    sort{ $b->{'pident'} <=> $a->{'pident'} }
      @all_hsps;
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

sub hsp {
  my ($self, $hsp, $opts, $colours) = @_;
  my ($hspstart, $hspend) = $self->region($hsp);
  ($hspstart, $hspend)  = ($hspend, $hspstart) if $hspend < $hspstart;
  my $identity            = sprintf("%.1f", ($hsp->{'pident'} /100));
  my $colour              = $colours->{$identity};

  my $h        = 5;
  my $score    = $hsp->{'score'};
  my $evalue   = $hsp->{'evalue'};
  my $glyph    = Sanger::Graphics::Glyph::Rect->new({
						     'x'            => $hspstart,
						     'y'            => 0,
						     'width'        => $hspend - $hspstart,
						     'height'       => $h,
						     'colour'       => $colour,
						     'bordercolour' => 'black',
                 'href'         => $self->href($hsp),  
						    });
  
  my $bump_start = int($glyph->x() * $opts->{'pix_per_bp'});
  $bump_start    = 0 if ($bump_start < 0);
  my $bump_end   = $bump_start + int($glyph->width() * $opts->{'pix_per_bp'}) +1;
  $bump_end      = $opts->{'bitmap_length'} if ($bump_end > $opts->{'bitmap_length'});
  my $row        = &Sanger::Graphics::Bump::bump_row(
						     $bump_start,
						     $bump_end,
						     $opts->{'bitmap_length'},
						     $opts->{'bitmap'},
						    );
  return if($opts->{'dep'} != 0 && $row >= $opts->{'dep'});
  $glyph->y($glyph->y() - (1.6 * $row * $h * $self->strand()));
  $self->push($glyph);
}

sub region {
  my ($self, $hsp) = @_;
  my $start = $hsp->{'qstart'};
  my $end   = $hsp->{'qend'}; 
  ($start, $end)  = ($end, $start) if $end < $start; 
  return ($start, $end);
}

sub href {
  my ( $self, $hsp, $type ) = @_;

  my $ticket_name = $hsp->{'data'}->{'_hub'}->param('tk');

  my $href = $self->_url({
    'species' => $self->species,
    'type'    => 'Blast',
    'tk'      => $ticket_name,
    'hid'     => $hsp->{'id'},
  });

  return $href;
}


1;

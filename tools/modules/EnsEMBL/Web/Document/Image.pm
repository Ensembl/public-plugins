package EnsEMBL::Web::Document::Image;

use strict;

use POSIX qw(ceil);

use Bio::EnsEMBL::VDrawableContainer;

use EnsEMBL::Web::TmpFile::Image;

sub karyotype {
  my ($self, $hub, $object, $highs, $config_name, $species) = @_;
  my @highlights = ref($highs) eq 'ARRAY' ? @$highs : ($highs);

  $config_name ||= 'Vkaryotype';
  my $sp = $hub->param('species') || $hub->species;
  $species     ||= $sp;
  my $chr_name;

  my $image_config = $hub->get_imageconfig($config_name);
  
  # set some dimensions based on number and size of chromosomes
  if ($image_config->get_parameter('all_chromosomes') eq 'yes') {
    my $total_chrs = @{$hub->species_defs->get_config( $species, 'ENSEMBL_CHROMOSOMES')};
    my $rows       = $hub->param('rows') || ceil($total_chrs / 18);
    my $chr_length = $hub->param('chr_length') || 200;
       $chr_name   = 'ALL';

    if ($chr_length) {
      $image_config->set_parameters({
        image_height => $chr_length,
        image_width  => $chr_length + 25,
      });
    }
    
    $image_config->set_parameters({ 
      container_width => $hub->species_defs->get_config($species, 'MAX_CHR_LENGTH'),
      rows            => $rows,
      slice_number    => '0|1',
    });
  } else {
    $chr_name = $object->seq_region_name if $object;
    
    my $seq_region_length = $object ? $object->seq_region_length : '';
    
    $image_config->set_parameters({
      container_width => $seq_region_length,
      slice_number    => '0|1'
    });
    
    $image_config->{'_rows'} = 1;
  }

  $image_config->{'_aggregate_colour'} = $hub->param('aggregate_colour') if $hub->param('aggregate_colour');

  # get some adaptors for chromosome data
  my ($sa, $ka, $da);
  
  return unless $species;

  my $db = $hub->databases->get_DBAdaptor('core', $species);
  
  eval {
    $sa = $db->get_SliceAdaptor,
    $ka = $db->get_KaryotypeBandAdaptor,
    $da = $db->get_DensityFeatureAdaptor
  };

  return $@ if $@;

  # create the container object and add it to the image
  $self->drawable_container = Bio::EnsEMBL::VDrawableContainer->new({    
    'web_species' => $species,
    sa  => $sa, 
    ka  => $ka, 
    da  => $da, 
    chr => $chr_name,
    format => $hub->param('export')
  }, $image_config, \@highlights) if($hub->param('_format') ne 'Excel');

  return undef; # successful
}

sub add_pointers {
  my ($self, $hub, $extra) = @_;

  my $config_name = $extra->{'config_name'};
  my @data        = @{$extra->{'features'}};
  my $species     = $hub->species;
  my $color       = lc($extra->{'color'} || $hub->param('col')) || 'red';     # set sensible defaults
  my $style       = lc($extra->{'style'} || $hub->param('style')) || 'rharrow'; # set style before doing chromosome layout, as layout may need tweaking for some pointer styles
  my $high        = { style => $style };
  my ($p_value_sorted, $html_id, $max_colour);
  my $i = 1;
  
  # colour gradient 
  my @gradient = @{$extra->{'gradient'}||[]};
  if ($color eq 'gradient' && scalar @gradient) {    
    my @colour_scale = $hub->colourmap->build_linear_gradient(@gradient); # making an array of the colour scale

    foreach my $colour (@colour_scale) {
      $p_value_sorted->{$i} = $colour;
      $i = sprintf("%.1f", $i + 0.1);
      $max_colour = $colour;
    }
  }

  foreach my $row (@data) {
    my $chr = $row->{'chr'} || $row->{'region'};
    $html_id =  ($row->{'html_id'}) ? $row->{'html_id'} : '';    
    my $col = $p_value_sorted->{sprintf("%.1f",$row->{'p_value'})};
    $col = $p_value_sorted->{sprintf("%.1f",  1 +($row->{'ident'} / 100) )} unless $col;

    my $point = {
      start   => $row->{'start'},
      end     => $row->{'end'},
      id      => $row->{'label'},
      col     => $col || $max_colour || $color,
      href    => $row->{'href'},
      html_id => $html_id,
    };
    
    if (exists $high->{$chr}) {
      push @{$high->{$chr}}, $point;
    } else {
      $high->{$chr} = [ $point ];
    }
  }
  
  return $high;
}


1;

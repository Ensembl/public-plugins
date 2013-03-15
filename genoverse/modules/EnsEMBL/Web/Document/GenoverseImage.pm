# $Id$

package EnsEMBL::Web::Document::GenoverseImage;

use strict;

use JSON qw(to_json);

use base qw(EnsEMBL::Web::Document::Image);

sub new {
  my ($class, $args) = @_;
  $args->{'species_defs'}  = $args->{'hub'}->species_defs;
  $args->{'image_configs'} = [ $args->{'image_config'} ];
  $args->{'toolbars'}{$_}  = $args->{'image_config'}->toolbars->{$_} for qw(top bottom);
  return bless $args, $class;
}

sub get_tracks {
  my $self         = shift;
  my $hub          = $self->{'hub'};
  my $image_config = $self->{'image_config'};
  my (@tracks, %reverse_order);
  
  foreach (map [ $_->get('display'), $_ ], @{$image_config->glyphset_configs}) {
    next if $_->[0] eq 'off';
    
    my ($display, $track) = @$_;
    my %genoverse = %{$track->get('genoverse') || {}};
    
    next if $genoverse{'remove'};
    
    my $glyphset  = $track->get('glyphset');
    my $classname = "Bio::EnsEMBL::GlyphSet::$glyphset";
    
    next unless $hub->dynamic_use($classname);
    
    # TODO: generate hover labels elsewhere
    $classname->new({ config => $image_config, my_config => $track, display => $display }); # needed to generate hover labels
    
    my $config = {
      id        => $track->id,
      name      => $track->get('name'),
      order     => $track->get('order'),
      depth     => $track->get('depth'),
      url       => $hub->url({ type => 'Genoverse', action => 'fetch_features', function => $glyphset, config => $image_config->{'type'}, __clear => 1 }),
      urlParams => { id => $track->id },
      %genoverse
    };
    
    my $height = $track->get('user_height');
    
    $config->{'height'}        = int $height                    if defined $height;
    $config->{'featureHeight'} = $track->get('height')          if $track->get('height');
    $config->{'autoHeight'}    = JSON::true                     if $track->get('auto_height');
    $config->{'threshold'}     = $track->get('threshold') * 1e3 if $track->get('threshold');
    $config->{'renderer'}      = $display                       if scalar @{$track->get('renderers')} > 4;
    
    $reverse_order{$config->{'id'}} = $config->{'order'} + 0 and next if $track->get('strand') =~ /[bx]/ && $track->get('drawing_strand') eq 'r';
    
    push @tracks, $config;
  }
  
  $_->{'orderReverse'} = $reverse_order{$_->{'id'}} for grep exists $reverse_order{$_->{'id'}}, @tracks;
  
  return \@tracks;
}

sub render {
  my $self         = shift;
  my $slice        = $self->{'slice'};
  my $image_config = $self->{'image_config'};
  my ($top_toolbar, $bottom_toolbar) = $self->render_toolbar(1e9);
  
  my $config = {
    tracks         => [ { type => 'Scaleline' }, { type => 'Scalebar' }, @{$self->get_tracks} ],
    autoHeight     => $image_config->get_option('auto_height') ? JSON::true : JSON::false,
    wheelAction    => $image_config->get_parameter('zoom') eq 'no' ? JSON::false : 'zoom',
    minSize        => $image_config->get_parameter('min_size') + 0,
    flanking       => $self->hub->param('flanking') + 0,
    chr            => $slice->seq_region_name,
    start          => $slice->start + 0,
    end            => $slice->end   + 0,
    chromosomeSize => $slice->seq_region_length + 0,
  };
  
  my $html = sprintf('
    <input type="hidden" class="panel_type" value="Genoverse" />
    <input type="hidden" class="image_config" value="%s" />
    <script>Ensembl.genoverseConfig = %s;</script>
    <div class="image_container canvas" style="width:%spx">
      %s
      <div class="drag_select">
        <div class="canvas_container"></div>
        %s
      </div>
      %s
    </div>',
    $image_config->{'type'},
    to_json($config),
    $self->{'image_width'},
    $top_toolbar,
    $self->hover_labels,
    $bottom_toolbar
  );
  
  $html .= '<span class="hidden drop_upload"></span>' if $image_config->get_node('user_data');

  return $html;
}

sub render_toolbar {
  my $self           = shift;
  my $hub            = $self->hub;
  my $image_config   = $self->{'image_config'};
  my $zoom           = $image_config->get_parameter('zoom') ne 'no';
  my ($top, $bottom) = $self->SUPER::render_toolbar(1e9);
  
  my $controls = sprintf('
    <div class="genoverse_controls%s">
      <span class="label">Scroll:</span>
      <div class="left"><button class="scroll scroll_left" title="Scroll left"></button></div><div class="right"><button class="scroll scroll_right" title="Scroll right"></button></div>
      %s
      <span class="label">Track height:</span>
      <div class="left"><button class="auto_height%s" title="%s" value="%s" ></button></div><div class="right"><button class="reset_height" title="Reset track heights" value="%s"></button></div>
      <span class="label">Drag/Select:</span>
      <div><button class="dragging on" title="Scroll to a new region"></button></div>
      %s
    </div>',
    $self->{'image_width'} < 800 ? ' narrow' : '',
    $zoom ? qq {
      <span class="label">Zoom:</span>
      <div class="left"><button class="zoom_in" title="Zoom in"></button></div><div class="right"><button class="zoom_out" title="Zoom out"></button></div>
    } : '',
    $image_config->get_option('auto_height') ? ' off' : '',
    $image_config->get_option('auto_height') ? 'Set tracks to fixed height' : 'Set tracks to auto-adjust height',
    $hub->url({ type => 'Genoverse', action => 'auto_track_heights',  function => undef, image_config => $image_config->{'type'} }),
    $hub->url({ type => 'Genoverse', action => 'reset_track_heights', function => undef, image_config => $image_config->{'type'} }),
    $zoom ? qq{
      <span class="label">Wheel:</span>
      <div><button class="wheel_zoom on" title="Zoom in or out"></button></div>
    } : ''
  );
  
  $bottom = '' unless $self->{'toolbars'}{'bottom'}; # setting height as 1e9 in render_toolbar forces bottom to be created, but it may not be required
  $_     .= $controls for grep $_, $top, $bottom;
  
  return ($top, $bottom);
}

sub hover_labels {
  my $self    = shift;
  my %filters = map { $_ => 1 } @_;
  my $img_url = $self->{'species_defs'}->img_url;
  my @labels  = values %{$self->{'image_config'}{'hover_labels'} || {}};
     @labels  = grep $filters{$_->{'class'}}, @labels if scalar keys %filters;
  my ($html, %done);
  
  foreach my $label (@labels) {
    next if $done{$label->{'class'}};
    
    my $desc = join '', map "<p>$_</p>", split /; /, $label->{'desc'};
    my $renderers;
    
    foreach (@{$label->{'renderers'}}) {
      $renderers .= sprintf(qq{
        <li class="$_->{'val'}%s">
          <a href="$_->{'url'}" class="config constant" rel="$label->{'component'}">
            <img src="${img_url}render/$_->{'val'}.gif" alt="$_->{'text'}" title="$_->{'text'}" />%s $_->{'text'}
          </a>
        </li>},
        $_->{'current'} ? (' current', qq{<img src="${img_url}tick.png" class="tick" alt="Selected" title="Selected" />}) : ('', '')
      );
    }
    
    $html .= sprintf(qq{
      <div class="hover_label floating_popup %s">
        <p class="header">%s</p>
        %s
        %s
        <img class="height" src="${img_url}blank.gif" alt="Height" title="" />
        %s
        <a href="$label->{'fav'}[1]" class="config constant favourite%s" rel="$label->{'component'}" title="Favourite track"></a>
        <a href="$label->{'off'}" class="config constant" rel="$label->{'component'}"><img src="${img_url}16/cross.png" alt="Turn track off" title="Turn track off" /></a>
        <div class="desc">%s</div>
        <div class="config">%s</div>
        <div class="height"><p class="auto">Set track to auto-adjust height</p><p class="fixed">Set track to fixed height</p></div>
        <div class="url">%s</div>
        <div class="spinner"></div>
      </div>},
      $label->{'class'},
      $label->{'header'},
      $label->{'desc'}     ? qq{<img class="desc" src="${img_url}16/info.png" alt="Info" title="Info" />}                                  : '',
      $renderers           ? qq{<img class="config" src="${img_url}16/setting.png" alt="Change track style" title="Change track style" />} : '',
      $label->{'conf_url'} ? qq{<img class="url" src="${img_url}16/link.png" alt="Link" title="URL to turn this track on" />}              : '',
      $label->{'fav'}[0]   ? ' selected' : '',
      $desc,
      $renderers           ? qq{<p>Change track style:</p><ul>$renderers</ul>}                                                : '',
      $label->{'conf_url'} ? qq{<p>Copy <a href="$label->{'conf_url'}">this link</a> to force this track to be turned on</p>} : ''
    );
  }
  
  return $html;
}

1;

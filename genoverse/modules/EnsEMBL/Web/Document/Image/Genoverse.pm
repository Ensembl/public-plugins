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

package EnsEMBL::Web::Document::Image::Genoverse;

use strict;

use JSON qw(to_json);

use parent qw(EnsEMBL::Web::Document::Image::GD);

sub new {
  my ($class, $hub, $component, $args) = @_;

  $args->{'species_defs'}  = $hub->species_defs;
  $args->{'height'}        = 1e9;

  return $class->SUPER::new($hub, $component, [ $args->{'image_config'} ], $args);
}

sub has_moveable_tracks {
  return 1;
}

sub get_tracks {
  my $self         = shift;
  my $hub          = $self->{'hub'};
  my $image_config = $self->{'image_config'};
  my (@tracks, %reverse_order);
  
  foreach (map [ $_->get('display'), $_ ], @{$image_config->glyphset_tracks}) {
    next if $_->[0] eq 'off';
    
    my ($display, $track) = @$_;
    my %genoverse = %{$track->get_data('genoverse') || {}};
    
    next if $genoverse{'remove'};
    
    my $glyphset  = $track->get('glyphset');
    my $classname = "EnsEMBL::Draw::GlyphSet::$glyphset";
    
    next unless $hub->dynamic_use($classname);
    
    my $glyphset_object = $classname->new({ config => $image_config, my_config => $track, display => $display });
    
    my $config = {
      id           => $track->id,
      name         => $track->get('caption'),
      order        => $track->get('order') + 0,
      depth        => $glyphset_object->depth,
      labelOverlay => $glyphset_object->label_overlay,
      url          => $hub->url({ type => 'Genoverse', action => 'fetch_features', function => $glyphset, config => $image_config->{'type'}, __clear => 1 }),
      urlParams    => { id => $track->id },
      %genoverse
    };
    
    my $height = $track->get('user_height');
    
    $config->{'user'}{'height'}     = int $height                    if defined $height;
    $config->{'user'}{'autoHeight'} = JSON::true                     if $track->get('auto_height');
    $config->{'featureHeight'}      = $track->get('height')          if $track->get('height');
    $config->{'threshold'}          = $track->get('threshold') * 1e3 if $track->get('threshold');
    $config->{'renderer'}           = $display                       if scalar @{$track->get('renderers')} > 4;
    
    $reverse_order{$config->{'id'}} = $config->{'order'} + 0 and next if $track->get('strand') =~ /[bx]/ && $track->get('drawing_strand') eq 'r';
    
    delete $config->{$_} for grep !defined $config->{$_}, keys %$config;
    
    push @tracks, $config;
  }
  
  $_->{'orderReverse'} = $reverse_order{$_->{'id'}} for grep exists $reverse_order{$_->{'id'}}, @tracks;
  
  return \@tracks;
}

sub render {
  my $self         = shift;
  my $slice        = $self->{'slice'};
  my $image_config = $self->{'image_config'};
  my ($top_toolbar, $bottom_toolbar) = $self->render_toolbar;
  
  my $config = {
    tracks          => [ { type => 'Scaleline' }, { type => 'Scalebar', stranded => 1 }, @{$self->get_tracks} ],
    trackAutoHeight => $image_config->get_option('auto_height') ? JSON::true : JSON::false,
    wheelAction     => $image_config->get_parameter('zoom') eq 'no' ? JSON::false : 'zoom',
    minSize         => $image_config->get_parameter('min_size') + 0,
    flanking        => $self->component->param('flanking') + 0,
    chr             => $slice->seq_region_name,
    start           => $slice->start + 0,
    end             => $slice->end   + 0,
    chromosomeSize  => $slice->seq_region_length + 0,
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
  my $self            = shift;
  my $hub             = $self->hub;
  my $image_config    = $self->{'image_config'};
  my $zoom            = $image_config->get_parameter('zoom') ne 'no';
  my ($top, $bottom)  = $self->SUPER::render_toolbar(@_);
  my $autoheight      = $image_config->get_option('auto_height');
  my $autoheight_url  = { 'type' => 'Genoverse', 'action' => 'auto_track_heights',  'function' => '', 'image_config' => $image_config->{'type'} };
  my $resetheight_url = { 'type' => 'Genoverse', 'action' => 'reset_track_heights', 'function' => '', 'image_config' => $image_config->{'type'} };

  my $controls = sprintf('
    <div class="genoverse_controls%s">
      <div>
        <span class="label">Scroll:</span>
        <div class="button"><button class="scroll scroll_left" title="Scroll left"></button></div>
        <div class="right button"><button class="scroll scroll_right" title="Scroll right"></button></div>
      </div>
      <div class="%s">
        <span class="label">Zoom:</span>
        <div class="button"><button class="zoom_in" title="Zoom in"></button></div>
        <div class="right button"><button class="zoom_out" title="Zoom out"></button></div>
      </div>
      <div>
        <span class="label">Track height:</span>
        <div class="button%s"><button class="auto_height" title="Fix track heights" value="%s"></button></div>
        <div class="right button%s"><button class="auto_height on" title="Auto-adjust track heights" value="%s"></button></div>
        <div class="right button"><button class="reset_height" title="Reset track heights" value="%s"></button></div>
      </div>
      <div>
        <span class="label">Drag/Select:</span>
        <div class="button selected"><button class="dragging on" title="Scroll to a region"></button></div>
        <div class="right button"><button class="dragging" title="Select a region"></button></div>
      </div>
      <div class="%s">
        <span class="label">Wheel:</span>
        <div class="button selected"><button class="wheel_zoom" title="Scroll the browser window"></button></div>
        <div class="right button"><button class="wheel_zoom on" title="Zoom in or out"></button></div>
      </div>
    </div>',
    $self->{'image_width'} < 800 ? ' narrow' : '',
    $zoom       ? '' : 'hidden',
    $autoheight ? '' : ' selected',
    $hub->url($autoheight_url),
    $autoheight ? ' selected' : '',
    $hub->url($autoheight_url),
    $hub->url($resetheight_url),
    $zoom       ? '' : 'hidden',
  );
  
  $bottom = '' unless $self->{'toolbars'}{'bottom'}; # setting height as 1e9 in render_toolbar forces bottom to be created, but it may not be required
  $_     .= $controls for grep $_, $top, $bottom;
  
  return ($top, $bottom);
}

sub hover_label_tabs {
  my $self  = shift;
  my $label = $_[0];

  my ($buttons, $contents) = $self->SUPER::hover_label_tabs(@_);

  splice @$buttons, -3, 0, sprintf(qq(<div class="_hl_icon hl-icon _track_height"><a href="#height" class="height" rel="$label->{'component'}"></a></div>));
  splice @$contents, -3, 0, qq(<div class="_hl_tab hl-tab _track_height"><p>Click on the icon to set track height to <span class="fixed_height">auto-adjust</span><span class="auto_height">fixed</span></p></div>);

  return ($buttons, $contents);
}

1;

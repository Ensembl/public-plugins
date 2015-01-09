=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Controller::Genoverse;

use strict;

use JSON qw(to_json from_json);
use List::Util qw(min);

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::Document::GenoverseImage;

use parent qw(EnsEMBL::Web::Controller);

sub new {
  my ($class, $r, $args) = @_;
  
  my $hub = new EnsEMBL::Web::Hub({
    apache_handle  => $r,
    session_cookie => $args->{'session_cookie'},
    user_cookie    => $args->{'user_cookie'},
  });
  
  my $func = $hub->action;
  my $self = { hub => $hub };
  
  bless $self, $class;
  
  $r->content_type('text/plain');
  $self->$func if $self->can($func);
  
  return $self;
}

sub fetch_features {
  my $self = shift;
  my $hub  = $self->hub;
  my @loc  = split ':', $hub->param('r');
  
  return print to_json({ error => 'Invalid location: ' . $hub->param('r') }) unless $loc[1] =~ /^\d+-\d+$/;
  
  my $action       = $hub->action;
  my $function     = $hub->function;
  my $image_config = $hub->get_imageconfig($hub->param('config'));
  my $referer      = $hub->referer;
  my $adaptor      = $hub->get_adaptor('get_SliceAdaptor');
  my $slice        = $adaptor->fetch_by_region('toplevel', shift @loc, split('-', shift @loc), @loc);
  my $chr          = $slice->seq_region_name;
  my $node         = $image_config->get_node($hub->param('id'));
  my $genoverse    = $node->get('genoverse');
  my ($func)       = grep $self->can($_), "fetch_$function", "fetch$function", 'fetch_features_generic';
  my (@features, %extra, $cache_url, $get_features);
  
  $self->{'cache'} = $hub->cache unless $genoverse->{'cache'} eq 'no';
  $self->{'json'}  = new JSON;
  $self->{'json'}->allow_blessed;
  
  $self->set_cache_params($slice, $node);
  
  # Needed to ensure zmenu links are correct
  $hub->type     = $referer->{'ENSEMBL_TYPE'};
  $hub->action   = $referer->{'ENSEMBL_ACTION'};
  $hub->function = $referer->{'ENSEMBL_FUNCTION'};
  
  foreach (@{$self->cache_bins}) {
    my $f = $self->get_cached_content('features', $chr, @$_);
    
    if ($f) {
      if ($slice->length == $slice->seq_region_length || $genoverse->{'all_features'}) {
        push @features, @$f;
      } else {
        # Reduce to only the features the region actually needs, to decrease transfer time and memory usage of the browser
        my ($s, $e) = ($slice->start, $slice->end);
        push @features, grep !($_->{'end'} < $s || $_->{'start'} > $e), @$f;
      }
    } elsif ($self->{'set_cache'}) {
      $f = $self->$func($adaptor->fetch_by_region('toplevel', $chr, @$_), $image_config, $function, $node);
      $self->set_cached_content($f, 'features', $chr, @$_);
      push @features, @$f unless $self->{'cache_url'};
    } else {
      $get_features = 1;
      $cache_url  ||= $self->{'cache_url'};
    }
  }
  
  @features = @{$self->$func($slice, $image_config, $function, $node)} if $get_features;
  ($func)   = grep $self->can($_), "extra_$function", "extra$function";
  
  if ($func) {
    %extra = ( %{$self->get_cached_content($chr) || {}}, %{$self->get_cached_content || {}} ) if $self->cache;
    
    if (!scalar keys %extra) {
      %extra = %{$self->$func($slice, $image_config, $function, $node) || {}};
      
      if ($self->{'set_cache'}) {
        my %extra_cache;
        $extra_cache{$self->{'caching'}{$_} eq 'chr' ? $chr : 0}{$_} = $extra{$_} for keys %extra;
        $self->set_cached_content($extra_cache{$_}, $_) for grep $extra_cache{$_}, $chr, 0;
      }
    }
  }
  
  return if $action eq 'set_cache';
  
  ($func) = grep $self->can($_), "highlight_$function", "highlight$function";
  
  $extra{'highlights'} = $self->$func($node)     if $func;
  $extra{'dataRange'}  = $self->{'cache_region'} if $genoverse->{'all_features'} && $self->{'cache_region'} && !$cache_url;
  $extra{'cacheURL'}   = $cache_url              if $cache_url;
  
  print $self->{'json'}->encode({ features => \@features, %extra });
}

sub fetch_features_generic {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my $hub        = $self->hub;
  my $strand     = $hub->param('strand');
  my ($glyphset) = $self->_use("EnsEMBL::Draw::GlyphSet::$function", {
    container => $slice,
    config    => $image_config,
    my_config => $node,
    display   => $node->get('display') || ($node->get('on') eq 'on' ? 'normal' : 'off'),
    strand    => $strand || 1
  });
  
  return unless $glyphset->can('features');
  
  my $colourmap = $hub->colourmap;
  my @features;
  
  foreach (@{$glyphset->features}) {
    my $colour_key = $glyphset->colour_key($_);
    my @tags       = grep ref $_ eq 'HASH' && $_->{'style'} ne 'join', $glyphset->tag($_);
    my $feature;
    
    foreach (@tags) {
      ($_->{'start'}, $_->{'end'}) = $glyphset->slice2sr($_->{'start'}, $_->{'end'});
      $_->{'color'}  = $colourmap->hex_by_name($_->{'colour'});
      $_->{'border'} = $colourmap->hex_by_name($_->{'border'}) if $_->{'border'};
    }
    
    my $feature = {
      start       => ($_->can('seq_region_start') ? $_->seq_region_start : $_->start) + 0,
      end         => ($_->can('seq_region_end')   ? $_->seq_region_end   : $_->end)   + 0,
      label       => $glyphset->feature_label($_),
      decorations => \@tags,
      $glyphset->genoverse_attributes($_),
    };
    
    $feature->{'strand'}     ||= int $_->strand if $strand;
    $feature->{'color'}      ||= $colourmap->hex_by_name($glyphset->my_colour($colour_key))          if $colour_key;
    $feature->{'labelColor'} ||= $colourmap->hex_by_name($glyphset->my_colour($colour_key, 'label')) if $colour_key && $feature->{'label'};
    $feature->{'labelColor'}   = $feature->{'color'} eq '#000000' ? '#FFFFFF' : '#000000' if $feature->{'color'} eq $feature->{'labelColor'} && $glyphset->label_overlay;
    $feature->{'menu'}       ||= $glyphset->href($_);
    $feature->{'title'}      ||= $glyphset->title($_) unless $feature->{'menu'};

    push @features, $feature;
  }
  
  return \@features;
}

sub fetch_gencode {
  return shift->fetch_transcript(@_);
}

sub fetch_transcript {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my $hub       = $self->hub;
  my $colourmap = $hub->colourmap;
  my $display   = $hub->param('renderer') || $node->get('display');
  my $no_label  = $display =~ /nolabel/;
  my $g         = $hub->core_params->{'g'};
  my $t         = $hub->core_params->{'t'};
  
  my ($glyphset) = $self->_use("EnsEMBL::Draw::GlyphSet::$function", {
    container => $slice,
    config    => $image_config,
    my_config => $node,
    display   => $display,
  });
  
  my @features;
  my ($genes, $highlights, $transcripts, $exons) = $glyphset->features;
  
  foreach my $gene (@$genes) {
    my $gene_id = $gene->stable_id;
    
    foreach ($transcripts->{$gene_id} ? @{$transcripts->{$gene_id}} : $gene) {
      my $stable_id  = $_->stable_id;
      my $transcript = $_->isa('Bio::EnsEMBL::Transcript') ? $_ : undef;
      my $colour_key = $glyphset->colour_key($gene, $transcript);
      my $feature    = {
        id         => $_->dbID,
        start      => $_->seq_region_start  + 0,
        end        => $_->seq_region_end    + 0,
        strand     => $_->seq_region_strand + 0,
        label      => $no_label ? '' : $glyphset->feature_label($gene, $transcript),
        color      => $colourmap->hex_by_name($glyphset->my_colour($colour_key)),
        labelColor => $colourmap->hex_by_name($glyphset->my_colour($colour_key, 'label')),
        legend     => $glyphset->my_colour($colour_key, 'text'),
        menu       => $glyphset->href($gene, $transcript),
        group      => scalar keys %$transcripts ? 1 : 0
      };
      
      if ($exons->{$gene_id} && !($transcript && $stable_id eq $gene_id)) {
        $feature->{'exons'} = [ map { id => $_->dbID, start => $_->seq_region_start + 0, end => $_->seq_region_end + 0 }, @{$exons->{$gene_id}} ];
      } elsif ($transcript) {
        foreach (@{$exons->{$stable_id}}) {
          push @{$feature->{'exons'}}, { id => $_->[0]->dbID, start => $_->[0]->seq_region_start + 0,       end => $_->[0]->seq_region_end + 0, style => 'strokeRect' } if $_->[1] eq 'border';
          push @{$feature->{'exons'}}, { id => $_->[0]->dbID, start => $_->[0]->seq_region_start + $_->[2], end => $_->[0]->seq_region_end + 0 - $_->[3]              } if $_->[1] eq 'fill';
        }
      }
      
      # save highlights which are not based on URL parameters (eg ccds transcripts in vega)
      $feature->{'highlight'} = $colourmap->hex_by_name($highlights->{$stable_id}) if $highlights->{$stable_id} && $stable_id ne $g && $stable_id ne $t;
      $feature->{'exons'}     = [ sort { $a->{'start'} <=> $b-> {'start'} || $a->{'end'} <=> $b-> {'end'} } @{$feature->{'exons'}} ] if $feature->{'exons'};
       
      push @features, $feature;
    }
  }
  
  return \@features;
}

sub fetch_structural_variation {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my $hub        = $self->hub;
  my ($glyphset) = $self->_use("EnsEMBL::Draw::GlyphSet::$function", {
    container => $slice,
    config    => $image_config,
    my_config => $node,
    display   => $node->get('display') || ($node->get('on') eq 'on' ? 'normal' : 'off'),
  });
  
  my $colourmap = $hub->colourmap;
  my $compact   = $glyphset->{'display'} eq 'compact';
  my @features;
  
  foreach my $f (@{$glyphset->features}) {
    my $colour_key = $glyphset->colour_key($f);
    my @tags       = grep ref $_ eq 'HASH' && $_->{'style'} ne 'join', $glyphset->tag($f);
    my ($feature, $breakpoint);
    
    foreach (@tags) {
      ($_->{'start'}, $_->{'end'}) = $glyphset->slice2sr($_->{'start'}, $_->{'end'});
      $_->{'color'}  = $colourmap->hex_by_name($_->{'colour'});
      $_->{'border'} = $colourmap->hex_by_name($_->{'border'}) if $_->{'border'};
      
      if (!$compact && $_->{'style'} eq 'somatic_breakpoint') {
        $breakpoint = 1;
        
        push @features, {
          $glyphset->genoverse_attributes($f),
          %$_,
          id          => $f->dbID . "_$_->{'start'}",
          featureId   => $f->dbID,
          start       => $_->{'start'} + 0,
          end         => $_->{'start'} + 0,
          length      => $f->length,
          menu        => $glyphset->href($f),
          decorations => [],
        };
      }
    }
    
    next if $breakpoint;
    
    my $feature = {
      start       => ($f->can('seq_region_start') ? $f->seq_region_start : $f->start) + 0,
      end         => ($f->can('seq_region_end')   ? $f->seq_region_end   : $f->end)   + 0,
      menu        => $glyphset->href($f),
      decorations => \@tags,
      $glyphset->genoverse_attributes($f),
    };
    
    $feature->{'color'} ||= $colourmap->hex_by_name($glyphset->my_colour($colour_key)) if $colour_key;

    push @features, $feature;
  }
  
  return \@features;
}

sub fetch_sequence {
  my ($self, $slice) = @_;
  
  return [{
    id       => join(':', $slice->start, $slice->end),
    start    => $slice->start + 0,
    end      => $slice->end   + 0,
    strand   => 1,
    sequence => $slice->seq
  }];
}

sub fetch_codonseq { return shift->fetch_sequence(@_); }

sub fetch_codons {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my $hub       = $self->hub;
  my $colourmap = $hub->colourmap;
  my @features;
  
  my ($glyphset) = $self->_use("EnsEMBL::Draw::GlyphSet::$function", {
    container => $slice,
    config    => $image_config,
    my_config => $node,
    display   => $node->get('display') || ($node->get('on') eq 'on' ? 'normal' : 'off')
  });

  for my $strand (1, -1) {
    foreach (@{$glyphset->features}) {
      push @features, {
        id     => join(':', $_->{'start'}, $_->{'end'}, $strand),
        start  => $_->{'start'} + 0,
        end    => $_->{'end'}   + 0,
        strand => $strand       + 0,
        y      => 2 * (($_->{'start'} - 1) % 3) + $_->{'y_inc'},
        color  => $colourmap->hex_by_name($_->{'colour'}),
      };
    }
  }
  
  return \@features;
}

sub fetch_synteny {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my @features;
  
  my ($glyphset) = $self->_use("EnsEMBL::Draw::GlyphSet::$function", {
    container => $slice,
    config    => $image_config,
    my_config => $node,
    display   => $node->get('display') || ($node->get('on') eq 'on' ? 'normal' : 'off')
  });
  
  foreach (@{$glyphset->features}) {
    push @features, {
      start => ($_->can('seq_region_start') ? $_->seq_region_start : $_->start) + 0,
      end   => ($_->can('seq_region_end')   ? $_->seq_region_end   : $_->end)   + 0,
      label => $glyphset->feature_label($_),
      menu  => $glyphset->href($_),
      $glyphset->genoverse_attributes($_),
    };
  }
  
  return \@features;
}

sub fetch_contig {
  my $self      = shift;
  my $features  = $self->fetch_features_generic(@_);
  my $colourmap = $self->hub->colourmap;
  my %colours   = ( 0 => 'contigblue1', 1 => 'contigblue2' );
  my $i         = 0;
  
  $_->{'color'} = $colourmap->hex_by_name($colours{$i++ % 2}) for @$features;
  
  return $features;
}

sub extra_sequence {
  my ($self, $slice, $image_config, $function, $node) = @_;
  my $hub       = $self->hub;
  my $colourmap = $hub->colourmap;
  my $extra     = {};
  
  if ($hub->param('colors') || $self->{'set_cache'}) {
    my $colourset = $hub->species_defs->colour($node->get('colourset'));
    
    foreach (keys %$colourset) {
      my $key = $_ eq 'default' ? $_ : uc;
      
      $extra->{'colors'}{$key}      = $colourmap->hex_by_name($colourset->{$_}{'default'});
      $extra->{'labelColors'}{$key} = exists $colourset->{$_}{'label'} ? $colourmap->hex_by_name($colourset->{$_}{'label'}) : $extra->{'colors'}{$key};
    }
  }
  
  return $extra;
}

sub extra_codonseq { 
  my $self = shift;
  my $extra = $self->extra_sequence(@_);
  $extra->{'codonTableId'} = ($_[0]->get_all_Attributes('codon_table')->[0] || {})->{'value'};
  $self->{'caching'}{'codonTableId'} = 'chr';
  return $extra;
}

sub extra_synteny {
  my ($self, $slice, $image_config, $function) = @_;
  my $hub = $self->hub;
  
  return unless $hub->param('colors') || $self->{'set_cache'};
  
  my $colourmap = $hub->colourmap;
  my $classname = "EnsEMBL::Draw::GlyphSet::$function";
  my $extra     = {};
  
  foreach (grep $_->get('glyphset') eq '_synteny', @{$image_config->glyphset_configs}) {
    my $id         = $_->id;
    my ($glyphset) = $self->_use($classname, {
      container => $slice,
      config    => $image_config,
      my_config => $_,
      display   => $_->get('display') || ($_->get('on') eq 'on' ? 'normal' : 'off')
    });
    
    $extra->{'colors'}{$_->{'hit_chr_name'}} ||= $colourmap->hex_by_name($glyphset->get_colours($_)->{'feature'}) for @{$glyphset->features};
  }
  
  $self->{'caching'}{'colors'} = 'chr';
  
  return $extra;
}

sub highlight_transcript {
  my ($self, $node) = @_;
  my $hub           = $self->hub;
  my $core_params   = $hub->core_params;
  my $gene          = $core_params->{'g'} ? $hub->get_adaptor('get_GeneAdaptor', $core_params->{'db'})->fetch_by_stable_id($core_params->{'g'}) : undef;
  
  return unless $gene;
  
  my $colourmap   = $hub->colourmap;
  my $transcripts = $node->get('display') =~ /transcript/;
  my $highlight   = $transcripts ? 'highlight1' : 'highlight2';
  my $highlights  = { $gene->dbID => $colourmap->hex_by_name($highlight) };
  
  if ($transcripts) {
    my $t = $core_params->{'t'};
    $highlights->{$_->dbID} = $colourmap->hex_by_name($_->stable_id eq $t ? 'highlight2' : $_->get_all_Attributes('ccds')->[0] ? 'lightblue1' : $highlight) for @{$gene->get_all_Transcripts};
  }
  
  return $highlights;
}

sub highlight_variation {
  my $self = shift;
  my $vf   = $self->hub->param('vf');
  return { $vf => '#000000' } if $vf;
}

sub update {
  my $self    = shift;
  my $hub     = $self->hub;
  my $referer = $hub->referer;
  
  # Needed to ensure hover label links are correct
  $hub->type     = $referer->{'ENSEMBL_TYPE'};
  $hub->action   = $referer->{'ENSEMBL_ACTION'};
  $hub->function = $referer->{'ENSEMBL_FUNCTION'};
  
  my $species      = $hub->species;
  my $view_config  = $hub->get_viewconfig($hub->param('config'), undef, 'cache');
  my $image_config = $hub->get_imageconfig($view_config->image_config);
  my $image        = new EnsEMBL::Web::Document::GenoverseImage({ hub => $hub, image_config => $image_config });
  my $tracks       = $image->get_tracks;
  my %existing     = map { split '=' } split ',', $hub->param('existing');
  my (@add, @change, @order);
  
  foreach my $track (@$tracks) {
    my $id       = $track->{'id'};
    my $renderer = $track->{'renderer'} || 1;
    my $exists   = $existing{$id};
    
    if (defined $exists) {
      push @change, [ $id, $renderer ] if $exists && $exists ne $renderer;
      $existing{$id} = 0;
    } else {
      push @add, $track;
    }
    
    push @order, [ $id, $track->{'order'} + 0, $track->{'orderReverse'} + 0 ];
  }
  
  print to_json({
    add        => \@add,
    change     => \@change,
    remove     => [ grep $existing{$_} ne '0', keys %existing ],
    labels     => scalar @add ? $image->hover_labels(map "${species}_$_->{'id'}", @add) : '',
    order      => \@order,
    viewConfig => { map { $_ => $view_config->get($_) } $view_config->options }
  });
}

sub save_config {
  my $self  = shift;
  my $hub   = $self->hub;
  my $track = $hub->param('track');
  
  return unless $track;
  
  my $image_config = $hub->get_imageconfig($hub->param('image_config'));
     $track        = $image_config->get_node($track);
  
  return unless $track;
  
  my $config = from_json($hub->param('config'));
   
  $track->set_user($_, $config->{$_} eq 'undef' ? undef : $config->{$_}) for keys %$config;
  $image_config->altered('Genoverse');
  $hub->session->store;
}

sub reset_track_heights {
  my $self         = shift;
  my $hub          = $self->hub;
  my $image_config = $hub->get_imageconfig($hub->param('image_config'));
  
  foreach my $track (grep $_->get('user_height') || $_->get('auto_height'), @{$image_config->glyphset_configs}) {
    $track->set_user($_, undef) for qw(user_height auto_height);
  }
  
  $image_config->get_node('auto_height')->set_user('display', 'off');
  $image_config->altered('Genoverse');
  $hub->session->store;
}

sub auto_track_heights {
  my $self         = shift;
  my $hub          = $self->hub;
  my $image_config = $hub->get_imageconfig($hub->param('image_config'));
  my $auto_height  = $hub->param('auto_height');
  my %json;
  
  foreach (map $_->get('display') ne 'off' ? [ $_, $_->get('auto_height'), $_->get('user_height') ] : (), @{$image_config->glyphset_configs}) {
    if ($auto_height) {
      $_->[0]->set_user('auto_height', ++$_->[1]) if $_->[1] || $_->[2];
    } elsif ($_->[1]) {
      $_->[0]->set_user('auto_height', --$_->[1] || undef);
    }
    
    $json{$_->[0]->id} = { autoHeight => $_->[1], height => int $_->[2] };
  }
  
  $image_config->get_node('auto_height')->set_user('display', $auto_height ? 'normal' : 'off');
  $image_config->altered('Genoverse');
  $hub->session->store;
  
  print to_json(\%json);
}

sub switch_image {
  my $self    = shift;
  my $hub     = $self->hub;
  my $session = $hub->session;
  my %args    = (type => 'image_type', code => $hub->param('id'));
  
  $session->purge_data(%args);
  $session->set_data(%args, static => $hub->param('static'));
}

sub set_cache { $_[0]->fetch_features; }

sub set_cached_content {
  my ($self, $content, @key) = @_;
  # JSON encode content so that numbers stay as numbers (otherwise they get stringified in the output)
  $self->cache->set(join('::', grep $_, $self->{'cache_key'}, @key), $self->{'json'}->encode($content), undef, values %{$ENV{'CACHE_TAGS'}}) if $self->cache;
}

sub get_cached_content {
  my ($self, @key) = @_;
  my $content = $self->cache ? $self->cache->get(join('::', grep $_, $self->{'cache_key'}, @key), values %{$ENV{'CACHE_TAGS'}}) : undef;
  return $self->{'json'}->decode($content) if $content;
}

sub set_cache_params {
  my ($self, $slice, $node) = @_;
  my $hub        = $self->hub;
  my $cache_bins = $self->cache_bins($slice, $node);
  
  return unless $self->cache;
  
  (my $renderer     = $hub->param('renderer')) =~ s/_(no)*label//;
  my $genoverse     = $node->get('genoverse');
  my ($start, $end) = ($cache_bins->[0][0], $cache_bins->[-1][1]);
  my $params        = {
    action   => 'set_cache',
    function => $hub->function,
    r        => sprintf('%s:%s-%s', $slice->seq_region_name, $start, $end),
    id       => $node->id,
    config   => $hub->param('config'),
    renderer => $renderer,
    __clear  => 1
  };
  
  $self->{'cache_key'}    = join '::', grep $_, 'Genoverse', $hub->species, $params->{'id'}, $params->{'renderer'};
  $self->{'set_cache'}    = $hub->action eq 'set_cache' || ($slice->start == 1 && $slice->end == $slice->seq_region_length); # The data will be cached if the url was /set_cache, or if the region is the entire chromosome
  $self->{'cache_region'} = { start => $start + 0, end => $end + 0 };                                                        # The region containing the data in the cache
  $self->{'cache_url'}    = $self->{'set_cache'} ? undef : $hub->url($params);                                               # The url to access in order to set the cache
  
  # Make sure that the threshold is big enough that data will be retrieved
  if ($self->{'set_cache'}) {
    $genoverse->{'threshold'}  = $self->{'bin_size'};
    $node->data->{'threshold'} = $genoverse->{'threshold'} / 1e3;
  }
  
  $ENV{'CACHE_TAGS'}{'page_type'} = 'GENOVERSE';
  $ENV{'CACHE_TAGS'}{'chr'}       = $slice->seq_region_name;
  $ENV{'CACHE_TAGS'}{'track_id'}  = $params->{'id'};
  $ENV{'CACHE_TAGS'}{'renderer'}  = $params->{'renderer'} if $params->{'renderer'};
}

sub cache_bins {
  my ($self, $slice, $node) = @_;
  
  if ($slice && $node && !$self->{'cache_bins'}) {
    my $start = $slice->start;
    my $end   = $slice->end;
    
    if ($self->cache) {
      my $genoverse = $node->get('genoverse');
      my $max       = $slice->seq_region_length;
      my $bin_size  = $self->{'bin_size'} = $genoverse->{'bin_size'} || ($genoverse->{'cache'} eq 'chr' ? $max : 5e7);
      my $low       = $start - ($start % $bin_size) + 1;
      my $high      = $end   - ($end   % $bin_size) + ($end % $bin_size ? $bin_size : 0);
      
      for (my $bin_start = $low; $bin_start < $high; $bin_start += $bin_size) {
        push @{$self->{'cache_bins'}}, [ $bin_start, min($bin_start + $bin_size - 1, $max) ];
      }
    } else {
      $self->{'cache_bins'} = [[ $start, $end ]];
    }
  }
  
  return $self->{'cache_bins'};
}

1;

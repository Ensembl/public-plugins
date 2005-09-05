package EnsEMBL::AJAX::Configuration::Location;

use strict;

use EnsEMBL::Web::Configuration;
our @ISA = qw( EnsEMBL::Web::Configuration );
use POSIX qw(floor ceil);

## Function to configure contigview

sub xx_contigview { 
  my $self = shift;
  my $flag = "_".($self->{'flag'}+0);
  warn $self->{object}->script;
  my $wsc = $self->{object}->get_scriptconfig('contigview');
  warn "PANELS... ", map { $_->{code} } @{ $self->{page}->content->{'panels'}||[] };
  $self->{page}->javascript->add_source( '/js/ajax.js' );
  $self->{page}->javascript->add_source( '/js/ensembl_ajax.js' );
  foreach my $K ( qw(ideogram overview bottom basepair) ) {
    my $key = "$K$flag";
    my $P = $self->{page}->content->panel( $key );
    if( $P ) {
      $P->replace_component( 
        'image',
        'EnsEMBL::AJAX::Configuration::Location::ajax_place_holder_'.$K,
        'no'
      );
      $self->{page}->add_body_attr( 'onLoad' => qq(load_image_into("@{[$self->{object}->species]}","${key}_image","@{[$self->get_parameters($K)]}");) );
    }
  }
}

sub get_parameters {
  my $self = shift;
  my $object = $self->{object};
  my $type = shift;
  my %pars = (
    'l'    => $object->seq_region_name.':'.$object->seq_region_start.'-'.$object->seq_region_end,
    'script' => 'contigview'
  );
  if( $type eq 'ideogram' ) {
    %pars = (
      %pars,
      's'            => 1,
      'e'            => $object->seq_region_length,
      'type'         => 'button',
      'user_config'  => 'chromosome'
    ); 
  } elsif( $type eq 'overview' ) {
    %pars = (
      %pars,
      's'            => $object->centrepoint - 500000,
      'e'            => $object->centrepoint + 500000,
      'type'         => 'button',
      'user_config'  => 'contigviewtop'
    );
  } elsif( $type eq 'bottom' ) {
    %pars = (
      %pars,
      's'            => $object->seq_region_start,
      'e'            => $object->seq_region_end,
      'type'         => 'imagemap',
      'user_config'  => 'contigviewbottom'
    );
  } else {
    %pars = (
      %pars,
      's'            => $object->centrepoint - 500,
      'e'            => $object->centrepoint + 500,
      'type'         => 'imagemap',
      'user_config'  => 'contigviewbottom'
    );
  }
  my $return = '';
  foreach (keys %pars) {
    $return .= sprintf ";%s=%s", $_, $pars{$_};
  }
  substr($return,0,1)='?';
  return $return;
}

sub ajax_place_holder_ideogram {
  my( $panel, $object ) = @_;
  ajax_place_holder( $panel, $object,
  {
    'sr'  => $object->seq_region_name,
    's'   => 1,
    'e'   => $object->seq_region_length,
    'wuc' => 'ideogram'
  });
}

sub ajax_place_holder_overview {
  my( $panel, $object ) = @_;
  ajax_place_holder( $panel, $object,
  {
    'sr'  => $object->seq_region_name,
    's'   => 1,
    'e'   => $object->seq_region_end,
    'wuc' => 'contigviewtop'
  });
}

sub ajax_place_holder_bottom {
  my( $panel, $object ) = @_;
  ajax_place_holder( $panel, $object,
  {
    'sr'  => $object->seq_region_name,
    's'   => $object->seq_region_start,
    'e'   => $object->seq_region_end,
    'wuc' => 'contigviewbottom'
  });
}

sub ajax_place_holder_basepair {
  my( $panel, $object ) = @_;
  ajax_place_holder( $panel, $object,
  {
    'sr'  => $object->seq_region_name,
    's'   => $object->centrepoint - 100,
    'e'   => $object->centrepoint + 100,
    'wuc' => 'contigviewbottom'
  });
}


sub ajax_place_holder {
  my( $panel, $object, $p ) = @_;
  my $width = $object->param('image_width');
  $panel->print( qq(<div style="width: ${width}px;" class="bg5 autocenter" id="$panel->{'code'}_image">
    <p style="padding: 2px; margin: 0px;">
      Generating image... please wait while image is fetched...<br />
      AJAX Call - WUC: $p->{'wuc'} of $p->{'sr'} $p->{'s'} -> $p->{'e'}
    </p>
  </div>));
}

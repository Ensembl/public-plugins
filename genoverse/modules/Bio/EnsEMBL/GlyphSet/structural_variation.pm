package Bio::EnsEMBL::GlyphSet::structural_variation;

use strict;

use Bio::EnsEMBL::Variation::Utils::Constants;

use previous qw(depth);

sub _labels { return $_[0]{'_labels'} ||= \%Bio::EnsEMBL::Variation::Utils::Constants::VARIATION_CLASSES; }
sub depth   { return $_[0]->PREV::depth if $_[0]{'container'}; }

sub genoverse_attributes { 
  my ($self, $f) = @_;
  my %attrs = $f->is_somatic && $f->breakpoint_order ? ( breakpoint => 1, height => 12, spacing => 9 ) : ();
  $attrs{'legend'} = $self->_labels->{$self->colour_key($f)}{'display_term'};
  return %attrs;
}

1;

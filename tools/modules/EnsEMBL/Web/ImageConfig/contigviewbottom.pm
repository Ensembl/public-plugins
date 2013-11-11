# $Id$

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;

sub get_sortable_tracks { return grep { $_->get('sortable') && ($_->get('menu') ne 'no' || $_->id eq 'blast_hit_btop') } @{$_[0]->glyphset_configs}; } # Add blast to the sortable tracks

1;

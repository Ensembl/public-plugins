package EnsEMBL::Web::Document::Page::Dynamic;

use strict;

sub modify_elements {
  $_[0]->remove_body_element('tabs');
}

1;
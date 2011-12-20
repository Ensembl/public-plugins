package EnsEMBL::Web::Object::HelpLink;

use strict;

use base qw(EnsEMBL::Web::Object::DbFrontend);

### ### ### ### ### ### ### ### ###
### Inherited method overriding ###
### ### ### ### ### ### ### ### ###

sub manager_class {
  ## @overrides
  return shift->rose_manager('HelpLink');
}

sub show_fields {
  ## @overrides
  return [
    'page_url'    => {
      'label' => 'Page URL',
      'type'  => 'string',
      'notee' => 'e.g. Gene/Location'
    }
  ];
}

sub show_columns {
  ## @overrides
  return ['page_url' => 'Page URL'];
}

1;
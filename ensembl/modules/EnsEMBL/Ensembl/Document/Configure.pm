package EnsEMBL::Ensembl::Document::Configure;

### Plugin menu configuration for a standard Ensembl website

use CGI qw(escapeHTML);
use EnsEMBL::Web::Root;
our @ISA  = qw(EnsEMBL::Web::Root);

sub common_menu_items {
### Addition menu items for site-specific content
### Stub - currently no items added
}

sub static_menu_items {
### Addition static-content-only menu items for site-specific content
### Stub - currently no items added
}

sub dynamic_menu_items {
### Addition dynamic-content-only menu items for site-specific content
### Stub - currently no items added
}

1;

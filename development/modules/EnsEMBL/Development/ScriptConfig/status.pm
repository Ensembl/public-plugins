package EnsEMBL::Development::ScriptConfig::status;

use strict;

sub init {
  warn "INIT CALLED";
  my ($script_config) = @_;

  $script_config->_set_defaults(qw(
    panel_apache on
  ));
}
1;


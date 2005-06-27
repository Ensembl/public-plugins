package EnsEMBL::Development::ScriptConfig::status;

use strict;

sub init {
  warn "INIT CALLED";
  my ($script_config) = @_;

  $script_config->_set_defaults(qw(
    panel_apache on
    panel_conf   off
  ));
}
1;


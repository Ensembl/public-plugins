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

package EnsEMBL::Web::Component::Tools::Down;

use strict;
use warnings;

use URI::Escape qw(uri_escape);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Exceptions;

use parent qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  $self->ajaxable(0);
}

sub content {
  my $self  = shift;
  my $sd    = $self->hub->species_defs;

  my $message;

  try {
    $message = file_get_contents($sd->TOOLS_UNAVAILABLE_MESSAGE_FILE);
  } catch {
    $message = $sd->TOOLS_UNAVAILABLE_MESSAGE;
  };

  return $self->_error('Temporarily Unavailable', sprintf '%s Please contact <a href="mailto:%s?subject=%s">%2$s</a> for more information.',
    $message || 'Web Tools are temporarily not available.',
    $sd->ENSEMBL_HELPDESK_EMAIL,
    uri_escape(sprintf 'Tools unavailable on %s', $sd->ENSEMBL_SERVERNAME)
  );
}

1;

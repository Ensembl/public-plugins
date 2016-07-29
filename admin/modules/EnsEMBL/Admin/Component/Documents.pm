=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Documents;

use strict;

use parent qw(EnsEMBL::Web::Component);

use EnsEMBL::Admin::Tools::DocumentParser qw(file_to_htmlnodes);

sub caption       { ''; }
sub short_caption { ''; }

sub get_display_html {
  my $self    = shift;
  my $object  = $self->object;
  my $dom     = $self->dom;
  my $file    = $object->get_parsed_file;
  my $message = $object->message;
  my $html    = '';

  $html .= $dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;
  $html .= file_to_htmlnodes($file, $dom)->render if $file;

  return $html;
}

1;
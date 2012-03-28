package EnsEMBL::Admin::Component::Documents;

use strict;

use base qw(EnsEMBL::Web::Component);

use EnsEMBL::Admin::Tools::DocumentParser qw(file_to_htmlnodes);

sub caption       { ''; }
sub short_caption { ''; }

sub get_display_html {
  my $self    = shift;
  my $object  = $self->object;
  my $dom     = $self->dom;
  my $file    = $object->get_parsed_file;
  my $message = $object->header_message;
  my $html    = '';

  $html .= $dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;
  $html .= file_to_htmlnodes($file, $dom)->render if $file;

  return $html;
}

1;
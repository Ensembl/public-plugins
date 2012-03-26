package EnsEMBL::Admin::Component::Documents::View;

use strict;

use base qw(EnsEMBL::Web::Component);

use EnsEMBL::Admin::Tools::DocumentParser qw(file_to_htmlnodes);

sub caption       { ''; }
sub short_caption { ''; }

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $dom     = $self->dom;
  my $file    = $object->get_parsed_file;
  my $message = $object->header_message;
  my $html    = '';

  if ($hub->function) {
    $html .= $dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;
    $html .= file_to_htmlnodes($file, $dom)->render if $file;
  } else {

    my $docs = $object->available_documents;
    while (my ($function, $title) = splice @$docs, 0, 2) {
      $html .= sprintf('<li><a href="%s">%s</a></li>', $hub->url({'function' => $function}), $title);
    }
    $html = $html ? "<h2>Document list</h2><p>Please select a document below to view:<ul>$html</ul></p>" : '<h2>No document found</h2><p>There is no document to display</p>';
  }

  return $html;
}

1;
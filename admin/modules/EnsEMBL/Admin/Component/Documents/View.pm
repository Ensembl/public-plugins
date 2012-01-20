package EnsEMBL::Admin::Component::Documents::View;

use strict;

use base qw(EnsEMBL::Web::Component);

use EnsEMBL::Admin::Tools::DocumentParser qw(file_to_htmlnodes);

sub caption {
  return '';
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $file    = $object->get_parsed_file;

  return file_to_htmlnodes($file, $self->dom)->render if $file;

  return sprintf('<h2>Document not found</h2><p>There was no document found corresponding to <b>%s</b></p>', $hub->function) if $hub->function;

  my $available_docs  = $object->available_documents;
  my $docs_list       = '';

  while (my ($function, $title) = splice @$available_docs, 0, 2) {
    $docs_list .= sprintf('<li><a href="%s">%s</a></li>', $hub->url({'function' => $function}), $title);
  }

  return "<h2>Document list</h2><p>Please select a document below to view:<ul>$docs_list</ul></p>" if $docs_list;

  return '<h2>No document found</h2><p>There is no document to display</p>';
}

1;
package EnsEMBL::Admin::Component::Documents::View;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;

  return $self->get_display_html if $hub->function;

  my $docs    = $object->available_documents;
  my $list    = '';
  while (my ($function, $doc) = splice @$docs, 0, 2) {
    $list .= sprintf('<li><a href="%s">%s</a></li>', $hub->url({'action' => 'View', 'function' => $function}), $doc->{'title'});
  }
  return $list ? "<h2>Document list</h2><p>Please select a document below to view:<ul>$list</ul></p>" : '<h2>No document found</h2><p>There is no document to display</p>';
}

1;
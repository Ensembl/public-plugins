package EnsEMBL::Admin::Component::Documents::Preview;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption       { my $title = shift->object->document_title; return $title ? "Preview $title" : ''; }
sub short_caption { return shift->caption;                                                            }

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $message = $object->header_message;

  return $self->dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;

  my $form = $self->new_form({'method' => 'post', 'action' => $hub->url({'action' => 'Save', 'function' => $hub->function})});
  $form->add_hidden({
    'name'        => 'post_document',
    'value'       => $object->get_raw_file
  });
  $form->add_field({
    'label'       => 'CVS commit message',
    'type'        => 'string',
    'name'        => 'post_cvs',
    'shortnote'   => sprintf(' by %s', $hub->user->email),
    'required'    => 1
  });
  $form->add_button({'value' => 'Save &amp; Commit to CVS'});

  return sprintf('<p><pre class="admin-doc-preview">%s PREVIEW STARTS %1$s</pre></p>%s<p><pre class="admin-doc-preview">%1$s PREVIEW ENDS %1$s</pre></p>%s', '&#8212;' x 20, $self->get_display_html, $form->render);
}

1;
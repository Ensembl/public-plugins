package EnsEMBL::Admin::Component::Documents::Edit;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption       { my $title = shift->object->document_title; return $title ? "Editing $title" : ''; }
sub short_caption { return shift->caption;                                                            }

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $message = $object->header_message;
  my $html    = '';

  return $self->dom->create_element('div', {'class' => 'embedded-box tinted-box', 'inner_HTML' => $message})->render if $message;

  my $form = $self->new_form({'method' => 'post', 'action' => $hub->url({'action' => 'Preview', 'function' => $hub->function})});
  $form->add_fieldset->append_child('textarea', {'cols' => '100', 'rows' => '60', 'name' => 'post_document', 'class' => 'admin-doc-edit', 'inner_HTML' => $object->get_raw_file || ''});
  $form->add_fieldset->add_button({'value' => 'Preview'});

  $html .= $form->render;

  return $html;
}

1;
package EnsEMBL::Admin::Component::Changelog::Preview;

## Preview page to add some validation on the content field before displaying the saving the declaration.
## TODO - add this validation and sanitisation to EnsEMBL::ORM::Component::DbFrontend::Input for html type elements and then remove this file

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::ORM::Component::DbFrontend::Input);

sub content_tree {
  my $self          = shift;
  my $url_params    = $self->get_url_params;
  my $declaration   = $url_params->{'content'};
  my ($div, $error);

  try {
    $div = $self->dom->create_element('div', {'inner_HTML' => [$declaration, 1]});
  } catch {
    $error = sprintf '<p>You seem to have entered invalid xHTML. There was an error while parsing it: %s</p><p>Please try again.</p>', $_->message;
  };

  return $self->error_content_tree($error) if $error;

  sanitise_html_node($div);

  $url_params->{'content'} = $div->inner_HTML;

  return $self->SUPER::content_tree($url_params);
}

sub sanitise_html_node {
  my $node = shift;

  return unless $node->node_type eq $node->ELEMENT_NODE; # ignore text nodes

  $_ =~ /^(alt|cell(padding|spacing)|class|(col|row)span|href|src|rel|title)$/ or $node->remove_attribute($_) for @{$node->attributes};

  foreach my $child (@{$node->child_nodes}) {

    # remove any extra line break (converted to empty <p> tag by tinymce)
    $child->remove if $child->node_name eq 'p' && ($child->inner_HTML =~ /^[\s\n\r\t]*$/ || $child->inner_HTML eq '&nbsp;');
    
    # remove any empty text node
    $child->remove if !$child->node_name && $child->text =~ /^[\s\n\r\t]*$/;

    # sanitise the child node
    sanitise_html_node($child);
  }
}

1;
package EnsEMBL::Admin::Component::Changelog::TextSummary;

### Module to produce an email-friendly list of all declarations for the release announcement

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  return '';
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $records = $object->rose_objects;
  my $release = $object->requested_release;

  my $html    = "Declarations of Intentions - Ensembl $release";
  $html       = sprintf('%s%s%s%s', '=' x length $html, "\n$html\n", '=' x length $html, "\n\n");

  my $current_team = '';

  for my $record (@$records) {

    # Team name
    my $team = $record->team;
    $html   .= sprintf("\n%s\n%s\n\n", $team, '=' x length $team) and $current_team = $team unless $current_team eq $team;

    # Title
    my $sp    = $record->species;
    my $title = sprintf("%s (%s)",
      $record->get_title || '(no title)',
      $sp && @$sp ? @$sp == 1 ? $sp->[0]->get_title : join ' and ', reverse((pop @$sp)->get_title, join(', ', @{[ map {$_->get_title} @$sp ]})) : 'All Species');
    $html .= sprintf("%s\n%s\n", $title, '-' x length $title);

    # Content
    $html .= sprintf("%s\n\n", $self->dom->create_element('div', {'inner_HTML' => [ $record->content, 1, 1 ]})->render_text); #parse HTML, ignore error and get text
  }

  return qq(<pre>$html</pre>);
}

1;

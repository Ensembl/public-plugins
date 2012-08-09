package EnsEMBL::Admin::Component::Changelog::TextSummary;

### Module to produce an email-friendly list of all declarations for the release announcement

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

use constant {
  COLUMN_WIDTH      => 70,
  MIN_COLUMN_WIDTH  => 40
};

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
  my $width   = $self->hub->param('width') || $self->COLUMN_WIDTH;
     $width   = $width =~ /^[0-9]{1,3}$/ ? $width < $self->MIN_COLUMN_WIDTH ? $self->MIN_COLUMN_WIDTH : $width : $self->COLUMN_WIDTH;
  my @lines;

  my $text    = "Declarations of Intentions - Ensembl $release";
  push    @lines, $text;
  push    @lines, {'text' => '=' x length $text, 'ignore_overflow' => 1}, '', '';
  unshift @lines, {'text' => '=' x length $text, 'ignore_overflow' => 1};

  my $current_team = '';

  for my $record (@$records) {

    # Team name
    my $team = $record->team;
    push @lines, $team, {'text' => '=' x length $team, 'ignore_overflow' => 1}, '' and $current_team = $team unless $current_team eq $team;

    # Title
    my $sp    = $record->species;
    my $title = sprintf("%s (%s)", $record->get_title || '(no title)', $sp && @$sp ? $self->join_with_and(map $_->get_title, @$sp) : 'All Species');
    push @lines, $title, {'text' => '-' x length $title, 'ignore_overflow' => 1};

    # Content
    push @lines, $self->dom->create_element('div', {'inner_HTML' => [ $record->content, 1, 1 ]})->render_text, '', ''; #parse HTML, ignore error and get text
  }

  my $form = $self->new_form({'method' => 'get'});
  $form->add_field({'label' => 'Column width', 'inline' => 1, 'field_class' => 'change-width', 'elements' => [
    {'type' => 'string', 'name' => 'width', 'value' => $width, 'maxlength' => 3, 'class' => 'change-width' },
    {'type' => 'submit', 'value' => 'Change'}
  ]});

  return sprintf q(%s<pre class="wrap">%s</pre>), $form->render, format_text($width, @lines);
}

sub format_text {
  my $width = shift;
  my @lines;
  for (@_) {
    my $text = ref $_ ? $_->{'text'} || '' : $_;
    if (ref $_ && $_->{'ignore_overflow'}) {
      push @lines, substr($text, 0, $width);
    } else {
      my @words = split /\s+/, $text;
      my @w     = $text eq '' ? ('') : ();
      while (@words) {
        if (length(join ' ', @w) < $width) {
          push @w, shift @words;
        } else {
          if (@w > 1) {
            unshift @words, pop @w;
          }
          push @lines, join(' ', @w);
          @w = ();
        }
      }
      push @lines, join(' ', @w) if @w;
    }
  }
  return join "\n", @lines;
}

sub join_with_and {
  ## TODO: remove this once it's added to Component.pm
  shift;
  return join(' and ', reverse (pop @_, join(', ', @_) || ()));
}

1;

package EnsEMBL::Admin::Component::Changelog::TextSummary;

### Module to produce an email-friendly list of all declarations for the release announcement

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::Data::User;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $builder = $self->builder;
  my $hub = $self->hub;
  my $release = $hub->species_defs->ENSEMBL_VERSION;
  my $html = qq(
<div style="font-family:monospace">
<p class="space-below">
=======================================<br />
Declarations of Intentions - Ensembl $release<br />
=======================================</p>
);

  my $data = $self->object('Changelog')->fetch_all;

  my ($item, $previous);

  ## Entries
  foreach $item (@$data) {
    next unless $item->content;
    if ($item->team ne $previous) {
      $html .= '<p class="space-below">'.$item->team.'<br />';
      my $underline = '=' x length($item->team);
      $html .= $underline.'</p>';
    }
    my $title = $item->title || '(No title)';

    (my $content = $item->content) =~ s/<ul>/<ul class="no-bullet">/g;
    $content =~ s/<li>/<li>* /g;
    
    my $sp_text;
    my @species = @{$item->species || []};
   
    if (!@species) {
      $sp_text = 'all species';
    }
    else {
      my @names;
      foreach my $sp (@species) {
        push @names, $sp->web_name;
      }
      $sp_text = join(', ', @names);
    }

    my $title_length = length($title) + length($sp_text) + 3;

    $html .= sprintf(qq(
<p>%s (%s)<br />%s</p>
<p class="space-below">%s</p>
<br /><br />
), 
        $title, $sp_text, ('-' x $title_length), $content
    );

    $previous = $item->team;
  }
  $html .= '</div>';
  return $html;
}

1;

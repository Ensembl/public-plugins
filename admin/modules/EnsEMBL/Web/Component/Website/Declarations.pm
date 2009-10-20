package EnsEMBL::Web::Component::Website::Declarations;

### Module to display all declarations in full

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::NewsItem;
use EnsEMBL::Web::Data::Species;

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
  my $object = $self->object;
  my $html = '<h1>Declarations in Full</h1>';

  my @declarations = EnsEMBL::Web::Data::NewsItem->search('release_id' => $object->species_defs->ENSEMBL_VERSION);

  my @sorted = sort {$a->team cmp $b->team} @declarations;
  my $previous;

  foreach my $item (@sorted) {
    if ($item->team ne $previous) {
      $html .= '<h2>'.$item->team.'</h2>';
    }
    my $title = $item->title || '(No title)';
    my $user = EnsEMBL::Web::Data::User->new($item->created_by);
    my $name = 'not logged';
    if ($user) {
      $name = $user->name;
    }
    my $sp_text;
    if (!$item->species) {
      $sp_text = 'all species';
    }
    else {
      my @names;
      foreach my $sp ($item->species) {
        if ($sp->common_name =~ /\./) {
          push @names, '<i>'.$sp->common_name.'</i>';
        }
        else {
          push @names, $sp->common_name;
        }
      }
      $sp_text = join(', ', @names);
    }
    $html .= sprintf(qq(
<h3>%s</h3>
<pre>%s</pre>
<p><strong>Species</strong>: %s</p>
<p><strong>Declared by</strong>: %s</p> 
<p><strong>Status</strong>: %s</p>
), 
        $title, $item->declaration, $sp_text, $name, $item->status
    );
    if ($item->team eq 'Genebuild') {
      $html .= sprintf(qq(
<ul>
<li><strong>New assembly?</strong> %s</li>
<li><strong>New gene set?</strong> %s</li>
<li><strong>Repeat masking?</strong> %s</li>
<li><strong>Stable ID mapping?</strong> %s</li>
<li><strong>Affy mapping?</strong> %s</li>
<li><strong>Database new/patched?</strong> %s</li>
</ul>
),
      $item->assembly, $item->gene_set, $item->repeat_masking, $item->stable_id_mapping, $item->affy_mapping, $item->database
);
    }
    $html .= '<hr />';
    $previous = $item->team;
  }

  return $html;
}

1;

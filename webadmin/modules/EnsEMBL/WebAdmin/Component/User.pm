package EnsEMBL::WebAdmin::Component::User;

use EnsEMBL::Web::Component;
use EnsEMBL::Web::Interface::InterfaceDef;
use EnsEMBL::Web::Data::Article;

use CGI;

use strict;
use warnings;

our @ISA = qw( EnsEMBL::Web::Component);

sub admin_home {
  my( $panel, $object ) = @_;
  my $modular = $object->species_defs->ENSEMBL_MODULAR_HELP;

  my $html = qq(
<h3>Help Database</h3>
<ul class="spaced">
<li><strong>Articles</strong>: <a href="/common/web/old_article?dataview=add">Add</a> | <a href="/common/web/old_article">View/edit</a></li>
<li><strong>Glossary</strong>: <a href="/common/web/glossary?dataview=add">Add</a> | <a href="/common/web/glossary">Edit</a></li>
</ul>
);
  }

  $html .= qq(
<h3>News Database</h3>

<ul class="spaced">
<li>Declarations of Intentions <a href="/common/web/declaration?dataview=add">Add</a> | <a href="/common/web/declaration">View/edit</a></li>
<li>News <a href="/common/web/news_item?dataview=add">Add</a> | <a href="/common/web/news_item">View/edit</a></li>
</ul>

);

  $panel->print($html);
  return 1;
}

1;


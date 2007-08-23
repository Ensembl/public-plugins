package EnsEMBL::WebAdmin::Component::User;

use EnsEMBL::Web::Component;

use CGI;

use strict;
use warnings;

our @ISA = qw( EnsEMBL::Web::Component);

sub admin_home {
  my( $panel, $object ) = @_;
  my $modular = $object->species_defs->ENSEMBL_MODULAR_HELP;

  my $html = qq(
<h3>Help Database</h3>
);
  if ($modular) {
    $html .= qq(
<h4>Old help schema</h4>

<p>This interface should be used if you are using the old help database schema, i.e. articles, glossary, etc in separate tables
);
  }

  $html .= qq(
<ul class="spaced">
<li><strong>Articles</strong>: <a href="/common/web/old_help_article?dataview=add">Add</a> | <a href="/common/web/old_help_article">View/edit</a></li>
<li><strong>Glossary</strong>: <a href="/common/web/old_glossary?dataview=add">Add</a> | <a href="/common/web/old_glossary">View/edit</a></li>
</ul>
);

  if ($modular) {
    $html .= qq(
<h4>New help schema (individual records)</h4>

<p>Tip: To delete a record, select 'edit' and then update its status to 'dead'</p>

<ul class="spaced">
<li><strong>Glossary</strong>: <a href="/common/web/glossary?dataview=add">Add</a> | <a href="/common/web/glossary">Edit</a></li>
</ul>
);
  }

  $html .= qq(
<h3>News Database</h3>

<ul class="spaced">
<li><a href=""></a></li>
</ul>

);

  $panel->print($html);
  return 1;
}

1;


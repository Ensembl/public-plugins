package EnsEMBL::WebAdmin::Component::User;

use EnsEMBL::Web::Component;
use EnsEMBL::Web::Interface::InterfaceDef;
use EnsEMBL::Web::Object::Data::Article;

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
<li><strong>Articles</strong>: <a href="/common/web/old_article?dataview=add">Add</a> | <a href="/common/web/old_article">View/edit</a> | <a href="/common/web/old_article">View/edit</a> | <a href="/common/web/all_articles">List all articles</a></li>
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

sub all_articles {
  my( $panel, $object ) = @_;

  my $html;
  my $interface = EnsEMBL::Web::Interface::InterfaceDef->new();
  my $data = EnsEMBL::Web::Object::Data::Article->new();
  $interface->data($data);
  $interface->discover;

  my %cat_lookup;
  my $cats = EnsEMBL::Web::Object::Data::find_all('EnsEMBL::Web::Object::Data::Category');
  foreach my $cat (@$cats) {
    $cat_lookup{$cat->id} = $cat->name;
  }


  my $records = $interface->record_list;
  if (scalar(@$records) > 0) {
    my $count = 0;
    $html = qq(<table class="ss tint">
<tr>
  <th>Title</th>
  <th>Keyword</th>
  <th>Category</th>
  <th>Status</th>
</tr>
    );
    foreach my $article (@$records) {
      my $art_string;
      if ($article->status eq 'in_use') {
        $art_string = '<a href="/common/web/old_article?id='.$article->id.';dataview=edit">'.$article->title.'</a>';
      }
      else {
        $art_string = $article->title;
      }
      my $bg = ($count % 2 == 0) ? 'bg1' : 'bg2';
      $html .= sprintf(qq(<tr class="%s">
  <td>%s</td>
  <td>%s</td>
  <td>%s</td>
  <td>%s</td>
</tr>
      ), $bg, $art_string, $article->keyword, $cat_lookup{$article->category_id}, $article->status);
      $count++;
    }
    $html .= "</table>\n";
  }
  else {
    $html = "<p>Sorry, no articles were found</p>";
  }
  $panel->print($html);
  return 1;
}


1;


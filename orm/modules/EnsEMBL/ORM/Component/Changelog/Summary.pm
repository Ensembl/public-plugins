package EnsEMBL::ORM::Component::Changelog::Summary;

### Module to display all declarations for the upcoming release

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
  my $model = $self->model;
  my $hub = $self->hub;
  my $release = $hub->species_defs->ENSEMBL_VERSION;
  warn ">>> RELEASE $release";
  my $html = "<h1>Changelog for Release $release</h1>";

  my $data = $self->model->object('Changelog')->fetch_all;

  my $previous;

  foreach my $item (@$data) {
    if ($item->team ne $previous) {
      $html .= '<h2>'.$item->team.'</h2>';
    }
    my $title = $item->title || '(No title)';

    my $content = $item->content;
    if ($content =~ /<p>/) {
      $content = '<p>'.$content.'</p>';
    }

    my $sp_text;
    my @species = @{$item->species || []};
   
    if (!@species) {
      $sp_text = 'all species';
    }
    else {
      my @names;
      foreach my $sp (@species) {
        if ($sp->web_name =~ /\./) {
          push @names, '<i>'.$sp->web_name.'</i>';
        }
        else {
          push @names, $sp->web_name;
        }
      }
      $sp_text = join(', ', @names);
    }

    my $status_colour = '#000'; ## BLACK
    if ($item->status eq 'handed_over') {
       $status_colour =  '#090'; ## GREEN
    }
    elsif ($item->status eq 'declared') {
      $status_colour = '#c00'; ## RED
    }

    $html .= sprintf(qq(
<h3>%s</h3>
<p>%s</p>
<p><strong>Species</strong>: %s</p>
<p><strong>Status</strong>: <span style="color:%s;font-weight:bold;">%s</span></p>
), 
        $title, $content, $sp_text, $status_colour, $item->status
    );

    ## Extra info for logged-in admin users 
    my $user = $self->hub->user;
    if ($user && $user->is_member_of($self->hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
      my $creator = EnsEMBL::Web::Data::User->new($item->created_by);
      my $name = 'not logged';
      if ($creator) {
        $name = $creator->name;
      }

      my $last_updated = $item->modified_by ? $item->modified_at : $item->created_at;
      if ($item->modified_by && $item->modified_by != $item->created_by) {
        my $modifier = EnsEMBL::Web::Data::User->new($item->modified_by);
        $last_updated .= ' by '.$modifier->name if $modifier;
      }
      $html .= sprintf(qq(
<p><strong>Declared by</strong>: %s</p> 
<p><strong>Last updated</strong>: %s</p>
), 
        $name, $self->pretty_date($last_updated, 'full')
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
          $item->assembly, $item->gene_set, $item->repeat_masking, $item->stable_id_mapping, $item->affy_mapping, $item->db_status
        );
      }
    }

    if ($user && $user->is_member_of($self->hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
      $html .= '<p style="margin-top:0.5em"><a href="/Changelog/Edit?id='.$item->changelog_id.'" style="text-decoration:none"><img src="/i/edit.gif" alt="" />  Edit this record</a> &middot; <a href="/Changelog/Display?id='.$item->changelog_id.'" style="text-decoration:none">View full record</a>';
    }

    $html .= '<hr />';
    $previous = $item->team;
  }
  return $html;
}

1;

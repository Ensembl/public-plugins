package EnsEMBL::Admin::Component::News::Summary;

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
  my $builder = $self->builder;
  my $hub = $self->hub;
  my $release = $hub->param('release') || $hub->species_defs->ENSEMBL_VERSION;

  my $data = $self->object('News')->fetch_published;
  unless ($data && @$data) {
    return "<p>No news found for release $release</p>";
  } 

  my $html = "<h1>News for Release $release</h1>";
  my $previous;

  foreach my $story (@$data) {
    next unless $story->content;
    if ($story->category->news_category_id ne $previous) {
      $html .= '<h2>'.$story->category->name.'</h2>';
    }
    my $title = $story->title || '(No title)';

    my $content = $story->content;
    if ($content =~ /<p>/) {
      $content = '<p>'.$content.'</p>';
    }

=pod
    my $sp_text;
    my @species = @{$story->species || []};
   
    if (!@species) {
      $sp_text = 'all species';
    }
    else {
      my @names;
      foreach my $sp (@species) {
        if ($sp->common_name =~ /\./) {
          push @names, '<i>'.$sp->common_name.'</i>';
        }
        else {
          push @names, $sp->common_name;
        }
      }
      $sp_text = join(', ', @names);
    }
<p><strong>Species</strong>: %s</p>
=cut

    $html .= sprintf(qq(
<h3>%s</h3>
<p>%s</p>
), 
        $title, $content
    );

    ## Extra info for logged-in admin users 
    my $user = $self->hub->user;
    if ($user && $user->is_member_of($self->hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
      my $creator = EnsEMBL::Web::Data::User->new($story->created_by);
      my $name = 'not logged';
      if ($creator) {
        $name = $creator->name;
      }

      my $last_updated = $story->modified_by ? $story->modified_at : $story->created_at;
      if ($story->modified_by && $story->modified_by != $story->created_by) {
        my $modifier = EnsEMBL::Web::Data::User->new($story->modified_by);
        $last_updated .= ' by '.$modifier->name if $modifier;
      }
      $html .= sprintf(qq(
<p><strong>Declared by</strong>: %s</p> 
<p><strong>Last updated</strong>: %s</p>
), 
        $name, $self->pretty_date($last_updated, 'full')
      );

    }

    if ($user && $user->is_member_of($self->hub->species_defs->ENSEMBL_WEBADMIN_ID)) {
      $html .= '<p style="margin-top:0.5em"><a href="/News/Edit?id='.$story->news_item_id.'" style="text-decoration:none"><img src="/i/edit.gif" alt="" />  Edit this record</a> &middot; <a href="/News/Display?id='.$story->news_item_id.'" style="text-decoration:none">View full record</a><div style="display:inline;float:right;margin-top:-20px;margin-right:20px"><a style="text-decoration: none;" href="#">Back to Top</a></div>';
    }

    $html .= '<hr />';
    $previous = $story->category->news_category_id;
  }
  return $html;
}

1;

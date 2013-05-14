package EnsEMBL::Web::Document::Element::AccountLinks;

use strict;

### TODO add shared bookmarks from group
### TODO limit total number of bookmarks shown
### TODO show bookmarks from current site only
### TODO order bookmarks by priority

use URI::Escape qw(uri_escape);
use HTML::Entities qw(encode_entities);

sub init {
  my ($self, $controller) = @_;
  my $hub   = $self->hub;
  my $title = $controller->page->title;
  $self->{'_bookmark_data'} = {
    name        => $title->get_short,
    description => $title->get,
    url         => $hub->species_defs->ENSEMBL_BASE_URL . $hub->url
  };
}

sub content {
  my $self = shift;

  return $self->hub->user
    ? sprintf('<div class="_account_holder"><div class="account-loading">Loading&hellip;</div><form action="/Ajax/accounts_dropdown">%s%s%s</form></div>',
        map sprintf('<input type="hidden" name="%s" value="%s" />', $_, encode_entities(uri_escape($self->{'_bookmark_data'}{$_}))), keys %{$self->{'_bookmark_data'}})
    : $self->content_no_user
  ;
}

sub content_no_user {
  my $self = shift;
  return sprintf('<a class="constant modal_link account-link _accounts_no_user" href="%s" title="Login/Register">Login/Register</a>',  $self->hub->url({qw(type Account action Login)}));
}

sub content_ajax {
  my $self      = shift;
  my $hub       = $self->hub;
  my $user      = $hub->user;
  my $bookmarks = $user ? $user->bookmarks : [];

  return $user
    ? sprintf('<a class="constant _accounts_link account-link" href="%s"><span class="acc-email">%s</span><span class="acc-arrow"><span>&#9660;</span><span class="selected">&#9650;</span></a>
        <div class="_accounts_dropdown accounts-dropdown">
          <h4>Bookmarks</h4>
          <div>%s</div>%s
          <h4>Account</h4>
          <div>
            <p><a href="%1$s" class="modal_link constant" title="User Account" rel="modal_user_data">Edit Settings</a></p>
            <p><strong><a href="%s" class="constant">Logout</a></strong></p>
          </div>
        </div>',
        $hub->PREFERENCES_PAGE,
        $user->email,
        join('', map {
          sprintf '<p><a href="%s" title="%s: %s" class="constant"><span>%2$s</span><span class="acc-bookmark-overflow">&#133;</span></a></p>',
            $hub->url({'type' => 'Account', 'action' => 'Bookmark', 'function' => 'Use', 'id' => $_->record_id, '__clear' => 1}),
            $_->name,
            $_->url
        } @$bookmarks) || '<p><i>No bookmark added</i></p>',
        @$bookmarks ? sprintf('
          <div>
            <p><a href="%s" class="modal_link constant">Bookmark this page</a></p>
            <p><a href="%s" class="modal_link constant" rel="modal_user_data">View all bookmarks</a></p>
          </div>',
          $hub->url({
            'type'        => 'Account',
            'action'      => 'Bookmark',
            'function'    => 'Add',
            map {$_ => $hub->param($_) || ''} qw(name description url)
          }),
          $hub->url({qw(type Account action Bookmark function View)})
        ) : '',
        $hub->url({qw(type Account action Logout)})
      )
    : $self->content_no_user
  ;
}

1;

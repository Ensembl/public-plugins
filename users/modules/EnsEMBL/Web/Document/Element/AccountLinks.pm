=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Document::Element::AccountLinks;

use strict;

### TODO add shared bookmarks from group
### TODO show bookmarks from current site only
### TODO order bookmarks by priority

use HTML::Entities qw(encode_entities);

use constant ACCOUNT_DROPDOWN_BOOKMARK_LIMIT => 5;

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
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;

  ## Avoid a /Ajax/accounts_dropdown request on every page view. Render the stable
  ## account link now, and let the JS fetch user-specific dropdown contents lazily.
  my $html  = $user
    ? sprintf('%s<div class="_accounts_dropdown accounts-dropdown"></div>', $self->_account_link($user))
    : $self->_anonymous_link($hub->users_available);

  return sprintf('<div class="_account_holder%s">%s%s</div>', $user ? ' _logged_in' : '', $html, $self->_bookmark_form);
}

sub content_ajax {
  my $self            = shift;
  my $hub             = $self->hub;
  my $users_available = $hub->users_available;
  my $user            = $users_available ? $hub->user : undef;
  my $bookmarks       = $user ? $user->bookmarks : [];

  ## The masthead only needs a short preview; the full list remains available from
  ## the account page, and limiting it keeps the lazy endpoint cheap.
  my @display_bookmarks = @$bookmarks;
  splice @display_bookmarks, ACCOUNT_DROPDOWN_BOOKMARK_LIMIT if @display_bookmarks > ACCOUNT_DROPDOWN_BOOKMARK_LIMIT;

  my $manage_link;
  my $site = $hub->species_defs->ENSEMBL_ACCOUNTS_SITE;
  if ($site) {
    $manage_link = sprintf('<a href="%s%s" rel="external" title="User Account">My Account</a>', $site, $hub->PREFERENCES_PAGE);
  }
  else {
    $manage_link = sprintf('<a href="%s" class="modal_link constant" title="User Account">My Account</a>', $hub->PREFERENCES_PAGE);
  }

  return $user
    ? sprintf('%s
        <div class="_accounts_dropdown accounts-dropdown">
          <h4>Bookmarks</h4>
          <div>%s</div>%s
          <h4>Account</h4>
          <div>
            <p>%s</p>
            <p><strong><a href="%s" class="constant">Logout</a></strong></p>
          </div>
        </div>',
        $self->_account_link($user),
        join('', map {
          sprintf '<p><a href="%s" title="%s: %s" class="constant"><span>%2$s</span><span class="acc-bookmark-overflow">&#133;</span></a></p>',
            $hub->url({'type' => 'Account', 'action' => 'Bookmark', 'function' => 'Use', 'id' => $_->record_id, '__clear' => 1}),
            $_->name,
            $_->url
        } @display_bookmarks) || '<p><i>No bookmark added</i></p>',
        sprintf('
          <div>
            <p><a href="%s" class="modal_link constant">Bookmark this page</a></p>'. ( @$bookmarks ?
           '<p><a href="%s" class="modal_link constant%s" rel="modal_user_data">View all bookmarks</a></p>' : '').
          '</div>',
          $hub->url({
            'type'        => 'Account',
            'action'      => 'Bookmark',
            'function'    => 'Add',
            map {$_ => $hub->param($_) || ''} qw(name description url)
          }),
          $hub->url({qw(type Account action Bookmark function View)}),
        ),
        $manage_link,
        $hub->url({qw(type Account action Logout)})
      )
    : $self->_anonymous_link($users_available)
  ;
}

sub _account_link {
  my ($self, $user) = @_;

  return sprintf('<a class="constant _accounts_link account-link" href="%s"><span class="acc-email">%s</span><span class="acc-arrow"><span>&#9660;</span><span class="selected">&#9650;</span></span></a>',
    $self->hub->PREFERENCES_PAGE,
    encode_entities($user->email)
  );
}

sub _anonymous_link {
  my ($self, $users_available) = @_;

  return sprintf('<a class="constant account-link _accounts_no_user%s" href="%s" title="%s">Login/Register</a>', $users_available
    ? (' modal_link', $self->hub->url({qw(type Account action Login)}), 'Login/Register')
    : (' _accounts_no_userdb', '#', 'User accounts are temporarily unavailable.')
  );
}

sub _bookmark_form {
  my $self          = shift;
  my $bookmark_data = $self->{'_bookmark_data'} || {};

  return sprintf('<form action="/Ajax/accounts_dropdown" style="display:none">%s</form>',
    join('', map sprintf('<input type="hidden" name="%s" value="%s" />', $_, encode_entities($bookmark_data->{$_})), keys %$bookmark_data)
  );
}

1;

package EnsEMBL::Web::Document::Element::AccountLinks;

use strict;

### TODO add shared bookmarks from group
### TODO limit total number of bookmarks shown
### TODO order bookmarks by priority


sub content {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;

  return $user
    ? sprintf('<a class="constant _accounts_link account-link" href="%s"><span class="acc-email">%s</span><span class="acc-arrow"><span>&#9660;</span><span class="selected">&#9650;</span></a>
        <div class="_accounts_dropdown accounts-dropdown">
          <h4>Bookmarks</h4>
          <div>%s</div>
          <div>
            <p><a href="%s" class="modal_link" title="User Account">Bookmark this page</a></p>
            <p><a href="%s" class="modal_link" title="User Account">View all bookmarks</a></p>
          </div>
          <h4>Account</h4>
          <div>
            <p><a href="%1$s" class="modal_link" title="User Account">Edit Settings</a></p>
            <p><a href="%s" class="modal_link" title="User Account">Change Password</a></p>
            <p><strong><a href="%s">Logout</a></strong></p>
          </div>
        </div>',
        $hub->url({qw(species Multi type Account action Preferences)}),
        $user->email,
        join('', map {sprintf '<p><a href="%s" title="%s: %1$s"><span>%2$s</span><span class="acc-bookmark-overflow">&#133;</span></a></p>', $_->url, $_->name} @{$user->bookmarks}) || '<p><i>No bookmark added</i></p>',
        $hub->url({qw(species Multi type Account action Bookmark function Add)}),
        $hub->url({qw(species Multi type Account action Bookmark function View)}),
        $hub->url({qw(species Multi type Account action ChangePassword)}),
        $hub->url({qw(species Multi type Account action Logout)})
      )
    : sprintf('<a class="constant modal_link account-link" href="%s" title="Login/Register">Login/Register</a>',  $hub->url({qw(species Multi type Account action Login)}))
  ;
}

1;
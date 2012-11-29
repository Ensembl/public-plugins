package EnsEMBL::Users::Component::Account;

### Base class for all the components in user accounts
### @author hr5

use strict;

use EnsEMBL::Users::Messages qw(get_message);

use base qw(EnsEMBL::Web::Component);

use constant {
  _JS_LINK            => '_jinline modal_link',
  _JS_LINK_SECTION    => '_jinline modal_link',
  _JS_LINK_SUBSECTION => '_jinline modal_link',
  _JS_LINK_FREE       => '_jinline modal_link',
#   _JS_LINK_SECTION    => '_jinline _jseclink',
#   _JS_LINK_SUBSECTION => '_jinline _jsseclink',
#   _JS_LINK_FREE       => '_jinline _jfreelink',
  _JS_SECTION         => '_jsec',
  _JS_SUBSECTION      => '_jssec',
  _JS_NOTIFICATION    => '_jnotif',
  _JS_CONFIRM         => '_jconfirm',
  _JS_CANCEL          => '_jcancel',
  _JS_REFRESH_URL     => '_js_refresh_url',
};

sub caption       {}
sub short_caption {}

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub wrapper_div {
  ## Returns a wraper div for sections in accounts page
  ## @param Hashref as accepted as second argument in dom->create_element, plus some extra keys
  ##  - padded    If on, will return the padded div
  ##  - js_panel  Name of the js_panel (optional)
  ## @return Div object
  my $self      = shift;
  my $params    = shift || {};
  my $js_panel  = delete $params->{'js_panel'};

  return $self->dom->create_element('div', {
    'class'       => [ delete $params->{'padded'} ? 'section-padded' : 'section', delete $params->{'class'}, $js_panel ? 'js_panel' : () ],
    'children'    => [ $js_panel ? {'node_name' => 'input', 'type' => 'hidden', 'value' => $js_panel, 'class' => 'panel_type'} : (), @{delete $params->{'children'} || []} ],
    %$params
  });
}

sub render_message {
  ## Prints a message on the page
  ## @param Code for the message
  ## @param Optional hashref with following keys
  ##  - error If flag kept on, message will be displayed as an error message
  ##  - back  URL to be provided to the back button, defaults to 'back' param in url (if missed, no back button is displayed)
  my ($self, $code, $params) = @_;

  if (my ($message, $heading) = reverse get_message($code, $self->hub)) {

    return sprintf '<div class="%s"><h3>%s</h3><div class="message-pad">%s</div></div>%s',
      $params->{'error'} ? 'error' : 'info',
      $heading || ($params->{'error'} ? 'Error' : 'Message'),
      $self->wrap_in_p_tag($message),
      ($params->{'back'} ||= $self->hub->param('back')) ? $self->link_back_button($params->{'back'}) : ''
    ;
  } else {
    return '';
  }
}

sub get_then_param {
  ## Gets the 'then' param for the url that needs to be followed after the login is done
  ## Use for Login type pages only.
  ## @return URL string, if any, undef otherwise
  my $self    = shift;
  my $hub     = $self->hub;
  my $referer = $hub->referer;
  my $then    = $hub->param('then') || ($referer->{'external'} ? $referer->{'absolute_url'} : '') || '';
     $then    = $hub->species_defs->ENSEMBL_BASE_URL.$hub->current_url if $hub->action !~ /^(Login|Register)$/ && $hub->function ne 'AddLogin'; # if ended up on this page from some 'available for logged-in user only' page for Account type
  return $then;
}

sub get_group_types {
  ## Gets the type of groups with the display text
  return [
    'open'          => 'Any user can see and join this group.',
    'restricted'    => 'Any user can see this group, but can join only if an administrator sends him an invitation or approves his request.',
    'private'       => 'No user can see this group, or send a request to join it. Only an administrator can send him an inivitation to join the group.'
  ];
}

sub get_notification_types {
  ## Gets the type of notifications settings saved in the db for a group admin
  return {
    'notify_join'   => 'Email me when someone joins the group',
    'notify_edit'   => 'Email me when someone edits the group information',
    'notify_share'  => 'Email me when someone shares something with the group'
  };
}

sub add_user_details_fields {
  ## Adds fields to a given form for registration page
  ## @param Field object to add fields to
  ## @param Hashref with keys:
  ##  - email         Email address string
  ##  - name          Name string
  ##  - organisation  Organisation string
  ##  - country       Country code
  ##  - email_notes   Notes to be added to email field
  ##  - button        Value attrib for the submit button, defaults to 'Register'
  ##  - no_list       Flag if on, will not add the field "Ensembl news list subscription"
  ##  - no_email      Flag if on, will skip adding email inout
  my ($self, $form, $params) = @_;

  $params     ||= {};
  my @lists     = $params->{'no_list'} ? () : @{$self->hub->species_defs->SUBSCRIPTION_EMAIL_LISTS};
  my $countries = $self->object->list_of_countries;

  $form->add_field({'label' => 'Name',          'name' => 'name',         'type' => 'string',   'value' => $params->{'name'}          || '',  'required' => 1 });
  $form->add_field({'label' => 'Email Address', 'name' => 'email',        'type' => 'email',    'value' => $params->{'email'}         || '',  'required' => 1, $params->{'email_notes'} ? ('notes' => $params->{'email_notes'}) : () }) unless $params->{'no_email'};
  $form->add_field({'label' => 'Organisation',  'name' => 'organisation', 'type' => 'string' ,  'value' => $params->{'organisation'}  || '' });
  $form->add_field({'label' => 'Country',       'name' => 'country',      'type' => 'dropdown', 'value' => $params->{'country'}       || '', 'values' => [ {'value' => '', 'caption' => ''}, sort {$a->{'caption'} cmp $b->{'caption'}} map {'value' => $_, 'caption' => $countries->{$_}}, keys %$countries ] });

  if (@lists) {
    my $values = [];
    push @$values, {'value' => shift @lists, 'caption' => shift @lists, 'checked' => 1} while @lists;
    $form->add_field({
      'label'   => sprintf('%s news list subscription', $self->site_name),
      'type'    => 'checklist',
      'name'    => 'subscription',
      'notes'   => 'Tick the box corresponding to the email list you would wish to subscribe to',
      'values'  => $values,
    });
  }

  $form->add_button({'value' => $params->{'button'} || 'Register'});
}

sub select_group_form {
  ## Displays form to select one of the given groups
  ## @param Hashref with keys:
  ##  - memberships : membership objects for the groups to be displayed (arrayref)
  ##  - type        : checklist or dropdown (dropdown by default)
  ##  - action      : action attrib for the form
  ##  - label       : label for the dropdown element
  ##  - name        : name attrib for the downdown element - default to 'id'
  ##  - selected    : value of the selected option (id of the selected group)
  ##  - submit      : value attrib for the submit button
  my ($self, $params) = @_;

  my $form = $self->new_form({'action' => $params->{'action'} || '', 'method' => 'get'});
  $form->add_field({
    'label'   => $params->{'label'} || 'Select a group',
    'type'    => $params->{'type'} eq 'checklist' ? 'checklist' : 'dropdown',
    'name'    => $params->{'name'} || 'id',
    'values'  => [ map {$_ = $_->group; {'value' => $_->group_id, 'caption' => $self->html_encode($_->name)}} @{$params->{'memberships'} || []} ],
    $params->{'selected'} ? ('value' => $params->{'selected'}) : ()
  });
  $form->add_field({
    'type'    => 'submit',
    'value'   => $params->{'submit'} || 'Go'
  });

  return $form;
}

sub select_bookmark_form {
  ## Displays form to select one of the given bookmarks
  ## @param Hashref with keys:
  ##  - bookmarks   : bookmark objects (arrayref)
  ##  - action      : action attrib for the form
  ##  - label       : label for the element
  ##  - name        : name attrib for the element - default to 'id'
  ##  - selected    : value of the selected option (id of the selected bookmark)
  ##  - multiple    : flag if on, will make the field a checklist, otherwise it will be a radiolist
  ##  - submit      : value attrib for the submit button
  my ($self, $params) = @_;

  my $form = $self->new_form({'action' => $params->{'action'} || '', 'method' => 'get'});
  $form->add_field({
    'label'   => $params->{'label'} || 'Select a bookmark',
    'type'    => $params->{'multiple'} ? 'checklist' : 'radiolist',
    'name'    => $params->{'name'} || 'id',
    'values'  => [ map {
      'value'   => $_->record_id,
      'caption' => {'inner_HTML' => sprintf(
        '%s (<a href="%s" title="%s">View</a>)<br><i>%s</i>',
          map $self->html_encode($_), $_->name, $self->hub->url({'type' => 'Account', 'action' => 'Bookmark', 'function' => 'Use', 'id' => $_->record_id}), $_->url, $_->shortname || ''
        )
      }
    }, @{$params->{'bookmarks'} || []} ],
    $params->{'selected'} ? ('value' => $params->{'selected'}) : ()
  });
  $form->add_field({
    'type'    => 'submit',
    'value'   => $params->{'submit'} || 'Go'
  });

  return $form;
}

sub bookmarks_table {
  ## Prints table with bookmarks
  ## @param Hashref with keys
  ##  - bookmarks : Arrayref of bookmarks (user record or group record rose objects)
  ##  - group     : Group object if all bookmarks belong to a group
  ##  - shared    : Flag kept on if each bookmark is shared with a group, but not same in all cases
  my ($self, $params) = @_;

  my $user        = $self->hub->user;
  my $group       = delete $params->{'group'};
  my $group_param = $group ? {'group' => $group->group_id} : {}; # extra param to go with each URL if group is provided
  my $is_admin    = $group && $user->is_admin_of($group);
  my $table       = $self->new_table([{
    'key'           => 'title',
    'title'         => 'Title',
    'width'         => '30%',
    'sort'          => 'html'
  }, {
    'key'           => 'desc',
    'title'         => 'Short Description',
    'width'         => $params->{'shared'} ? '30%' : '60%'
  }, $params->{'shared'} ? { # additional column for shared bookmarks only to display link to the group
    'key'           => 'group',
    'title'         => 'Group',
    'width'         => '30%',
    'sort'          => 'html'
  } : (), {
    'key'           => 'buttons',
    'title'         => '',
    'width'         => '10%',
    'sort'          => 'none'
  }], [], {'class' => 'tint', 'data_table' => 'no_col_toggle', 'exportable' => 0});

  # bookmark rows
  for (@{$params->{'bookmarks'}}) {
    my $bookmark_id   = $_->get_primary_key_value;
    my $bookmark_row  = { 'desc' => $self->html_encode($_->shortname) };
    my $bookmark_name = $self->html_encode($_->name);

    # column for shared bookmarks table only
    if ($params->{'shared'}) {
      $group          = $_->group;
      $is_admin       = $user->is_admin_of($group);
      my $group_id    = $group->group_id;
      $group_param    = {'group' => $group_id};
      my $group_name  = $self->html_encode($group->name);

      $bookmark_row->{'group'} = $self->js_link({
        'href'    => {'action' => 'Groups', 'function' => 'View', 'id' => $group_id},
        'caption' => $group_name,
        'helptip' => "View group: $group_name",
        'target'  => 'page'
      });
    }

    $bookmark_row->{'title'} = $self->js_link({
      'href'    => {'action' => 'Bookmark', 'function' => 'Use', 'id' => $bookmark_id, %$group_param},
      'caption' => $bookmark_name,
      'helptip' => "Visit page: $bookmark_name",
      'target'  => 'page'
    });

    $bookmark_row->{'buttons'} = sprintf '<div class="sprites-nowrap">%s</div>', join('',
      $self->js_link({
        'href'    => {'action' => 'Bookmark', 'function' => 'Edit', 'id' => $bookmark_id, %$group_param},
        'helptip' => 'Edit',
        'sprite'  => 'edit_icon',
        'target'  => 'section'
      }), $group
      ? $self->js_link({
        'href'    => {'action' => 'Bookmark', 'function' => 'Copy', 'id' => $bookmark_id, %$group_param},
        'helptip' => 'Copy to my bookmarks',
        'sprite'  => 'bookmark_icon',
        'target'  => 'none'
      })
      : $self->js_link({
        'href'    => {'action' => 'Share', 'function' => 'Bookmark', 'id' => $bookmark_id},
        'helptip' => 'Share with a group',
        'sprite'  => 'share_icon',
        'target'  => 'section'
      }),
      !$group || $is_admin || $_->created_by eq $user->user_id
      ? $self->js_link({
        'href'    => {'action' => 'Bookmark', 'function' => 'Remove', 'id' => $bookmark_id, %$group_param},
        'helptip' => 'Remove',
        'sprite'  => 'delete_icon',
        'confirm' => sprintf('You are about to remove the bookmark%s. This action can not be undone.', $group ? ' from the group' : ''),
        'target'  => 'none'
      }) : ()
    );

    $table->add_row($bookmark_row);
  }

  return $table->render;
}

sub no_bookmark_message {
  ## Returns html for displaying message in case no bookmark has been added by the user
  ## @param Flag if on, will add the link to create a new bookmark in the message
  sprintf '<p>You have not saved any bookmarks to your account.%s</p>', $_[1]
    ? sprintf(' To add a new bookmark first, please <a href="%s">click here</a>.', $_[0]->hub->url({'action' => 'Bookmark', 'function' => 'Add'}))
    : ''
  ;
}

sub two_column {
  ## Generates HTML for a two column table
  ## @param Arrayref (name-value pair) of data to be printed
  ## @return HTML string
  my ($self, $data) = @_;
  my $table = $self->dom->create_element('table', {
    'class'     => 'ss fixed tint',
    'children'  => [{'node_name' => 'colgroup', 'children' => [ map {'node_name' => 'col', 'width' => $_}, qw(30% 70%) ]}]
  });
  my @bg    = qw(bg2 bg1);
  while (my ($left, $right) = splice @$data, 0, 2) {
    $table->append_child('tr', {
      'class'     => $bg[0],
      'children'  => [
        {'node_name' => 'td', 'inner_HTML' => $left},
        {'node_name' => 'td', 'inner_HTML' => $right}
      ]
    });
    @bg = reverse @bg;
  }
  return $table->render;
}

sub js_link {
  ## Returns HTML for a link that is used by JavaScript for inline editing
  ## @param Hashref with keys:
  ##  - href    : href attrib or hashref as accepted by hub->url
  ##  - caption : inner html
  ##  - title   : title attrib value
  ##  - helptip : same as 'title' , but will display it as a js helptip
  ##  - button  : flag if on, will wrap the link in <p>
  ##  - target  : section, subsection, page, modal or none
  ##  - class   : String or arrayref of class for <a> tag
  ##  - confirm : confirmation message to be displayed when the link is clicked - make sure its HTML escaped before calling this method
  ##  - cancel  : section id if this link is a 'cancel' link - will remove the given section
  ##  - sprite  : Class for the sprite icon (caption, cancel, button args will be ignored if this is provided)
  ## @return HTML string
  my ($self, $params) = @_;

  my $method = $params->{'sprite'} || !$params->{'button'} ? 'inner_HTML' : 'render';

  return $self->dom->create_element('p', {
    'class'       => 'accounts-button',
    'children'    => [{
      'node_name'   => 'a',
      'class'       => $self->_get_js_class_for_link($params),
      'href'        => ref $params->{'href'} ? $self->hub->url($params->{'href'}) : $params->{'href'},
      'inner_HTML'  => $params->{'sprite'} ? qq(<span class="sprite $params->{'sprite'}"></span>) : $params->{'caption'} || '',
      $params->{'helptip'} || $params->{'title'} ? (
        'title'     => $params->{'helptip'} || $params->{'title'}
      ) : ()
    }, $params->{'confirm'} ? {
      'node_name'   => 'span',
      'class'       => [ $self->_JS_CONFIRM, 'hidden' ],
      'inner_HTML'  => $params->{'confirm'}
    } : ()
  ]})->$method;
}

sub js_section {
  ## Generates a JavaScript refreshable section
  ## @param Hashref with keys:
  ##  - heading           : Heading of the section (h2)
  ##  - class             : CSS class name (optional)
  ##  - subheading        : Heading with h3 tag
  ##  - subsections       : Arrayref of subsections (html string or child of DOM::Node)
  ##  - refresh_url       : URL to refresh the page
  ##  - heading_links     : Links to be added just next to the heading - hashref can have following keys:
  ##    - href              : As accepted bu hub->url
  ##    - title             : Goes to title attrib of the icon
  ##    - sprite            : class for sprite icon
  ##    - target            : target for the link, ie. page, section or subsection (as in js_link)
  ##  - subheading_links  : Links to be added just next to the subheading, accepts keys same as in heading_links
  ##  - id                : Unique ID attrib of section - for JS to remember it while refreshing the section
  ##  - js_panel          : js_panel name (optional)
  my ($self, $params) = @_;
  my $js_subsection   = $self->_JS_SUBSECTION;
  my $links           = {'heading' => '', 'subheading' => ''};

  for (qw(heading subheading)) {
    if ($params->{$_}) {
      $links->{$_} = join('', map {
        sprintf '<a href="%s" class="header-link _ht _ht_static %s" title="%s"><span class="sprite %s"></span></a>', $self->hub->url($_->{'href'}), $self->_get_js_class_for_link($_), $_->{'title'}, $_->{'sprite'}
      } @{$params->{"${_}_links"} || []});
    }
  }

  return sprintf q(<div id="_%s" class="section %s%s%s">%s%s%s<input type="hidden" name="%s" value="%s">%s%s</div>),
    $params->{'id'},
    $self->_JS_SECTION,
    $params->{'class'}      ? " $params->{'class'}"                                                         : '',
    $params->{'js_panel'}   ? ' js_panel'                                                                   : '',
    $params->{'js_panel'}   ? qq(<input type="hidden" class="panel_type" value="$params->{'js_panel'}" />)  : '',
    $params->{'heading'}    ? "<h1>$params->{'heading'}$links->{'heading'}</h1>"                            : '',
    $params->{'subheading'} ? "<h2>$params->{'subheading'}$links->{'subheading'}</h2>"                      : '',
    $self->_JS_REFRESH_URL,
    ref $params->{'refresh_url'} ? $self->hub->url($params->{'refresh_url'}) : $params->{'refresh_url'},
    join('', map {qq(<div class="subsection $js_subsection">$_</div>)} @{$params->{'subsections'} || []}),
    $self->object->is_inline_request ? $self->js_link({'caption' => 'Cancel', 'class' => 'cancel', 'href' => '#Cancel', 'cancel' => $params->{'id'}, 'button' => 1}) : '' #TODO
  ;
}

sub link_back_button {
  ## Gets HTML for a button to add a bookmark
  ## @param back button's href
  ## @return HTML string
  my ($self, $href) = @_;
  return $self->js_link({'href' => $href, 'caption' => 'Go back', 'class' => 'arrow-left', 'target' => 'page', 'button' => 1});
}

sub _get_js_class_for_link { #TODO classes for different target tyes
  ## @private
  ## @param Hashref with keys: class, target and cancel as in args for js_link
  my ($self, $params) = @_;
  return join ' ', ( $params->{'cancel'} && !$params->{'sprite'} ? ($self->_JS_CANCEL, $self->_JS_CANCEL."_$params->{'cancel'}") : ({
    'page'        => $self->_JS_LINK, # TODO
    'subsection'  => $self->_JS_LINK_SUBSECTION,
    'none'        => $self->_JS_LINK_FREE,
    'modal'       => $self->_JS_LINK,
  }->{$params->{'target'}} || $self->_JS_LINK_SECTION),
  $params->{'class'} ? ref $params->{'class'} ? @{$params->{'class'}} : $params->{'class'} : (),
  $params->{'helptip'} ? '_ht' : () );
}

1;

package EnsEMBL::Users::Component::Account;

### Base class for all the components in user accounts
### @author hr5

use strict;

use base qw(EnsEMBL::Web::Component);

use constant {
  _JS_LINK            => '_jinline modal_link',
  _JS_LINK_SECTION    => '_jinline _jseclink',
  _JS_LINK_SUBSECTION => '_jinline _jsseclink',
  _JS_LINK_FREE       => '_jinline _jfreelink',
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
  ## @param Hashref as accepted as second argument in dom->create_element, plus an extra key
  ##  - padded If on, will return the padded div
  ## @return Div object
  my $self    = shift;
  my $params  = shift || {};

  return $self->dom->create_element('div', {'class' => sprintf('%s %s', delete $params->{'padded'} ? 'section-padded' : 'section', delete $params->{'class'}), %$params});
}

sub render_message {
  ## Prints a message on the page
  ## @param Code for the message
  ## @param Optional hashref with following keys
  ##  - error If flag kept on, message will be displayed as an error message
  ##  - back  URL to be provided to the back button, defaults to 'back' param in url (if missed, no back button is displayed)
  my ($self, $code, $params) = @_;

  if (my $message = $self->object->get_message($code)) {

    return sprintf '<div class="%s"><h3>%s</h3><div class="message-pad">%s</div></div>%s',
      $params->{'error'} ? 'error' : 'info',
      $params->{'error'} ? 'Error' : 'Message',
      $self->wrap_in_p_tag($message),
      ($params->{'back'} ||= $self->hub->param('back')) ? $self->link_back_button($params->{'back'}) : ''
    ;
  } else {
    return '';
  }
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
  my ($self, $form, $params) = @_;

  $params     ||= {};
  my @lists     = $params->{'no_list'} ? () : @{$self->hub->species_defs->SUBSCRIPTION_EMAIL_LISTS};
  my $countries = $self->object->list_of_countries;

  $form->add_field({'label' => 'Name',          'name' => 'name',         'type' => 'string',   'value' => $params->{'name'}          || '',  'required' => 1 });
  $form->add_field({'label' => 'Email Address', 'name' => 'email',        'type' => 'email',    'value' => $params->{'email'}         || '',  'required' => 1, $params->{'email_notes'} ? ('notes' => $params->{'email_notes'}) : () });
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
  ##  - action      : action attrib for the form
  ##  - label       : label for the dropdown element
  ##  - name        : name attrib for the downdown element - default to 'id'
  ##  - selected    : value of the selected option (id of the selected group)
  ##  - submit      : value attrib for the submit button
  my ($self, $params) = @_;

  my $form = $self->new_form({'action' => $params->{'action'} || ''});
  $form->add_field({
    'label'   => $params->{'label'} || 'Select a group',
    'type'    => 'dropdown',
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

  my $form = $self->new_form({'action' => $params->{'action'} || ''});
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
  ##  - bookmarks: Arrayref of bookmarks (user record or group record rose objects)
  ##  - group    : Id of the group if the bookmarks belong to a group
  my ($self, $params) = @_;

  my $table = $self->new_table([
    {'key' => 'title',   'title' => 'Title',              'width' => '30%', 'sorting' => 'sort_html'},
    {'key' => 'desc',    'title' => 'Short Description',  'width' => '70%'},
  ], [], {'data_table' => 'no_col_toggle', 'exportable' => 0});

  my %group_id_param = $params->{'group'} ? ('group' => $params->{'group'}) : ();

  for (@{$params->{'bookmarks'}}) {
    my $bookmark_id = $_->get_primary_key_value;
    $table->add_row({
      'desc'  => $self->html_encode($_->shortname),
      'title' => sprintf('%s%s%s<a href="%s">%s</a>',
        $self->js_link({
          'href'    => {'action' => 'Bookmark', 'function' => 'Edit', 'id' => $bookmark_id, %group_id_param},
          'title'   => 'Edit',
          'class'   => 'icon icon-pencil',
          'inline'  => 1
        }),
        $self->js_link({
          'href'    => {'action' => 'Bookmark', 'function' => 'Remove', 'id' => $bookmark_id, %group_id_param},
          'title'   => 'Remove',
          'class'   => 'icon icon-delete',
          'confirm' => sprintf('You are about to remove the bookmark%s. This action can not be undone.', keys %group_id_param ? ' from the group' : ''),
          'inline'  => 1
        }),
        %group_id_param
        ? $self->js_link({
          'href'    => {'action' => 'Bookmark', 'function' => 'Copy', 'id' => $bookmark_id, %group_id_param},
          'title'   => 'Copy to my bookmarks',
          'class'   => 'icon icon-download',
          'inline'  => 1
        })
        : $self->js_link({
          'href'    => {'action' => 'Share', 'function' => 'Bookmark', 'id' => $bookmark_id},
          'title'   => 'Share with a group',
          'class'   => 'icon icon-share',
          'inline'  => 1
        }),
        $self->hub->url({'action' => 'Bookmark', 'function' => 'Use', 'id' => $bookmark_id, %group_id_param}),
        $self->html_encode($_->name)
      )
    });
  }
  return $table->render;
}

sub no_membership_found_page {
  ## Gets js section for a page to display if the user is not a member of any group
  ## @param Optional hashref to be passed to js_section method
  my ($self, $params) = @_;
  return $self->js_section({
    'heading'     => 'Groups',
    %{$params || {}},
    'subsections' => [
      q(<p>You are not a member of any group.</p>),
      $self->link_create_new_group,
      $self->link_join_existing_group
    ]
  });
}

sub no_bookmark_found_page {
  ## Gets js section for a page to display if the user does not have bookmark saved
  ## @param Optional hashref to be passed to js_section method
  my ($self, $params) = @_;
  return $self->js_section({
    'heading'     => 'Bookmarks',
    %{$params || {}},
    'subsections' => [
      q(<p>You have not saved any bookmark.</p>),
      $self->link_add_bookmark
    ]
  });
}

sub two_column {
  ## Generates HTML for a two column table
  ## @param Arrayref (name-value pair) of data to be printed
  ## @return HTML string
  my ($self, $data) = @_;
  my $table = $self->dom->create_element('table', {
    'class'     => 'ss fixed',
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
  ##  - inline  : flag if on, will not wrap the link in <p>
  ##  - target  : section (default) or subsection or page
  ##  - class   : String or arrayref of class for <a> tag
  ##  - confirm : confirmation message to be displayed when the link is clicked - make sure its HTML escaped before calling this method
  ##  - cancel  : section id if this link is a 'cancel' link - will remove the given section
  ## @return HTML string
  my ($self, $params) = @_;

  return $self->dom->create_element('p', {
    'class'       => 'accounts-button',
    'children'    => [{
      'node_name'   => 'a',
      'class'       => [
        $params->{'cancel'} ? ($self->_JS_CANCEL, $self->_JS_CANCEL."_$params->{'cancel'}") : ({
          'page'        => $self->_JS_LINK,
          'subsection'  => $self->_JS_LINK_SUBSECTION,
          'none'        => $self->_JS_LINK_FREE
        }->{$params->{'target'}} || $self->_JS_LINK_SECTION),
        $params->{'class'}  ? ref $params->{'class'} ? @{$params->{'class'}} : $params->{'class'} : (),
      ],
      'href'        => ref $params->{'href'} ? $self->hub->url($params->{'href'}) : $params->{'href'},
      'inner_HTML'  => $params->{'caption'} || '',
      $params->{'title'} ? (
        'title'     => $params->{'title'}
      ) : ()
    }, $params->{'confirm'} ? {
      'node_name'   => 'span',
      'class'       => [ $self->_JS_CONFIRM, 'hidden' ],
      'inner_HTML'  => $params->{'confirm'}
    } : ()
  ]})->$_ for ($params->{'inline'} ? 'inner_HTML' : 'render');  
}

sub js_section {
  ## Generates a JavaScript refreshable section
  ## @param Hashref with keys:
  ##  - heading     : Heading of the section (h2)
  ##  - subheading  : Heading with h3 tag
  ##  - subsections : Arrayref of subsections (html string or child of DOM::Node)
  ##  - refresh_url : URL to refresh the page
  ##  - id          : Unique ID attrib of section - for JS to remember it while refreshing the section
  my ($self, $params) = @_;
  my $js_subsection = $self->_JS_SUBSECTION;

  return sprintf q(<div id="_%s" class="section %s">%s%s<input type="hidden" name="%s" value="%s">%s%s</div>),
    $params->{'id'},
    $self->_JS_SECTION,
    $params->{'heading'}    ? "<h2>$params->{'heading'}</h2>"     : '',
    $params->{'subheading'} ? "<h3>$params->{'subheading'}</h3>"  : '',
    $self->_JS_REFRESH_URL,
    ref $params->{'refresh_url'} ? $self->hub->url($params->{'refresh_url'}) : $params->{'refresh_url'},
    join('', map {qq(<div class="subsection $js_subsection">$_</div>)} @{$params->{'subsections'} || []}),
    $self->object->is_inline_request ? $self->js_link({'caption' => 'Cancel', 'class' => 'cancel', 'href' => '#Cancel', 'cancel' => $params->{'id'}}) : ''
  ;
}

sub link_create_new_group {
  ## Gets HTML for a button to create new group
  ## @return HTML string
  return shift->js_link({'href' => {qw(action Groups function Add)}, 'caption' => 'Create new group', 'class' => 'user-group-add', 'target' => 'section' });
}

sub link_join_existing_group {
  ## Gets HTML for a button to join an existing group
  ## @return HTML string
  return shift->js_link({'href' => {qw(action Groups function List)}, 'caption' => 'Join an existing group', 'class' => 'user-group-join', 'target' => 'page' });
}

sub link_add_bookmark {
  ## Gets HTML for a button to add a bookmark
  ## @return HTML string
  return shift->js_link({'href' => {qw(action Bookmark function Add)}, 'caption' => 'Add a bookmark', 'class' => 'bookmark-add'});
}

sub link_back_button {
  ## Gets HTML for a button to add a bookmark
  ## @param back button's href
  ## @return HTML string
  my ($self, $href) = @_;
  return $self->js_link({'href' => $href, 'caption' => 'Go back', 'class' => 'arrow-left'});
}

1;
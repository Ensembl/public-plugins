package EnsEMBL::Admin::Component::Healthcheck::Details;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable( 0 );
  $self->configurable( 0 );
}

sub caption {
  return 'Healthcheck details';
}

sub _param {
  ##@return the parameter for the requested view eg. 'core' if view is dbtype
  ##override it in the child class
  return '';
}

sub _type {
  ##@return view type. eg. database_type, species etc
  ##override it in the child class
  return '';
}

sub _get_first_column_for_report {
  ##@return heading for the first column of the spreadsheet
  ##override it in the child class
  return '';
}

sub _get_user_link {
  ##looks up the given hash of all users for given id
  ##@param $all     HashRef of all Rose::Object::User objects
  ##@param $user_id ID of the required user
  ##@return   <a href="mailto:$user_email">$user_id</a>
  ##override it in the child class
  my ($self, $all, $user_id) = @_;
  for (@$all) {
    return '<a href="mailto:'.$_->email.'">'.$_->name.'</a>' if $_->user_id == $user_id;
  }
  return 'unknown user';
}

sub _show_anchors {
  ##@return flag to decide wheather to display links at the top of the page linking to tables inside the page
  ##override it in the child class if no anchors need to be displayed
  return 1;
}

sub _get_default_list {
  ##@return a list (ArrayRef) of all species/database types/database names etc based on child class
  ##override it in the child class
  return [];
}

sub content {
  ##this method is called by Panel to display this method's return HTML inside the page
  ##@return HTML to be displayed
  my $self = shift;
  
  my $hub               = $self->hub;
  my $db_interface      = $self->object;
  my $release           = $hub->param('release') || $hub->species_defs->ENSEMBL_VERSION; #switch back to current release if no GET param 'release' found
  
  my $html              = '';
  my $html_anchors      = '';
  my $filter_param      = $self->_param;
  my $type              = $self->_type;
  (my $type_title       = ucfirst($type)) =~ s/_/ /;  #for printing

  return $self->NO_HEALTHCHECK_FOUND unless $self->validate_release($release);
  
  my $last_session          = $db_interface->data_interface('Session')->fetch_last($release);
  my $last_session_id       = $last_session ? $last_session->session_id || 0 : 0;
        
  return $self->NO_HEALTHCHECK_FOUND unless $last_session_id;
 
  my $report_db_interface   = $db_interface->data_interface('Report');

  unless ($filter_param) {
    #if no filter param is found, print a list of all Species/DBTypes (whichever required) etc
    my $reports = $report_db_interface->fetch_all_failed_for_session($last_session_id);
    return qq(<p class="hc_p">Click on a $type_title to view details</p>).
              $self->content_failure_summary($type, $last_session_id, $release, $reports);
  }
  
  my $reports = $report_db_interface->fetch_failed_for_session($last_session_id, { $type => $filter_param });
  
  return qq(<p class="hc_p">No healthcheck reports found for $type_title '$filter_param'.</p>) unless scalar @$reports;
  
  my $all_admin_users   = $db_interface->data_interface('User')->fetch_by_group(0); #TODO replace 0 by group_id for admin users once fetch_by_group is working properly - hr5
  
  #group all reports by database_name
  my $grouped_reports   = {};
  for (@$reports) {
    $grouped_reports->{ $_->database_name } = [] unless exists $grouped_reports->{ $_->database_name };
    push @{ $grouped_reports->{ $_->database_name } }, $_ ;
  }
  
  $html_anchors    .= "<h3>List of affected databases:</h3><ul>";
  my $serial_number = 0;
  
  my $hidden_input = $self->_param_name ne '' ? '<input type="hidden" name="'.$self->_param_name.'" value="'.$self->_param.'" />' : '';
  $html .= qq(<form action="" method="get"><p class="hc_p_right">View in release: ).$self->render_all_releases_selectbox($release).qq(&nbsp;<input type="submit" value="Go" />$hidden_input</p></form>);
  $html .= qq{<div class="hc-infobox">
            <p>For each database, reports are sorted on the basis of Date (initial failure date) with latest report appearing on the top.</p>
            <p>Reports in <span class="hc-problem">this colour</span> have not been annotated 'manual ok'.</p>
            <p>Reports appearing <span class="hc-problem hc-new">bold</span> (or <span class="hc-new">bold</span>) are for the recently appeared problems.</p>
  </div>};
  my $js_ref = 0;
  foreach my $database_name (keys %$grouped_reports) {
  
    $js_ref++; #counter used by JavaScript only
    $html          .= qq(<a name="$database_name"></a><h3 class="hc-dbheading">$database_name</h3>);
    $html_anchors  .= qq(<li><a href="#$database_name">$database_name</a></li>);

    my $table       = $self->new_table;
    
    $table->add_columns(#note - use the space properly, we have too much to display in annotation and text columns
#      {'key' => 'serial',   'title' => '',                                                'align' => 'right'},
      {'key' => 'db_sp_tc', 'title' => $self->_get_first_column_for_report,               'width' => qq(20%)},
      {'key' => 'text',     'title' => 'Text',                                            'width' => qq(40%)},
      {'key' => 'comment',  'title' => 'Annotation',                                      'width' => qq(40%)},
      {'key' => 'team',     'title' => 'Team/person responsible',                         'width' => '100px'},
      {'key' => 'created',  'title' => '<abbr title="Initial Failure Date">Date</abbr>',  'width' => '60px' },
    );
    
    #sort reports on the basis of creation time 
    my $i = 0;
    my $db_reports = [];
    my $temp = { map { ($_->created || '0').++$i => $_ } @{ $grouped_reports->{ $database_name } } };
    push @$db_reports, $temp->{ $_ } for reverse sort keys %$temp;
      
    foreach my $report (@{ $db_reports }) {
      my $report_id  = $report->report_id;
      my $db_sp_tc   = [];
      for (qw(database_type species testcase)) {
        next if $_ eq $type;
        push @$db_sp_tc, $self->get_healthcheck_link({'type' => $_, 'param' => ucfirst($report->$_), 'release' => $release, 'cut_long' => 'cut'});
      }

      #annotation column
      my $annotation    = '';
      if ($report->annotation) {
        $annotation    .= $report->annotation->comment if $report->annotation->comment;
        my $modified_by = '';
        my $created_by  = '';
        if ($report->annotation->created_by) {      
          $created_by  .= '<p class="hc-comment-info">Added by: '.$self->_get_user_link($all_admin_users, $report->annotation->created_by);
          $created_by  .= ' on '.$self->hc_format_date($report->annotation->created_at) if $report->annotation->created_at;
          $created_by  .= '</p>';
        }
        if ($report->annotation->modified_by) {
          $modified_by .= '<p class="hc-comment-info">Modified by: '.$self->_get_user_link($all_admin_users, $report->annotation->modified_by);
          $modified_by .= ' on '.$self->hc_format_date($report->annotation->modified_at) if $report->annotation->modified_at;
          $modified_by .= '</p>';
        }
        (my $temp       = $created_by) =~ s/Added/Modified/;
        $modified_by    = '' if $modified_by eq $temp;
        $annotation    .= $created_by.$modified_by;
        $annotation    .= '<p class="hc-comment-info">Action: '.$self->annotation_action($report->annotation->action)->{'title'}.'</p>'
          if $report->annotation->action && $self->annotation_action($report->annotation->action)->{'value'} ne '';
      }
      my $temp          = $report->annotation ? $report->annotation->action || '' : '';
      my $text_class    = $temp =~ /manual_ok|healthcheck_bug/ ? 'hc-noproblem' : 'hc-problem';
      $text_class      .= ' hc-new' if $report->first_session_id == $report->last_session_id;

      my $link_class    = join ' ', keys %{{ map { $_."-link" => 1 } split (' ', $text_class)}};

      $annotation      .= $annotation eq ''
        ? qq(<p class="hc-comment-link"><a class="$link_class" href="/Healthcheck/Annotation?rid=$report_id" rel="$js_ref">Add Annotation</a></p>)
        : qq(<p class="hc-comment-link"><a class="$link_class" href="/Healthcheck/Annotation?rid=$report_id" rel="$js_ref">Edit</a></p>);
  
      $table->add_row({
#        'serial'    => ++$serial_number.'.',
        'db_sp_tc'  => join ('<br />', @$db_sp_tc),
        'comment'   => $annotation,
        'text'      => qq(<span class="$text_class">).join (', ', split (/,\s?/, $report->text)).'</span>', #split-joining is done to wrap long strings (with no space) tending to expand the table wider than the page
        'team'      => $self->space_before_capitals($report->team_responsible),
        'created'   => $report->created ? $self->hc_format_compressed_date($report->created) : '<i>unknown</i>',
      });
    }

    $html .= $table->render;
  }
  $html_anchors .= '</ul>';
  return $self->_show_anchors ? $html_anchors.$html : $html; #return HTML (with anchors if flag is true)
}

1;

package EnsEMBL::Admin::Component::Healthcheck::Details;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  my $object = shift->object;
  my $extra  = $object->view_type && $object->view_param ? sprintf(' (%s)', $object->view_param) : '';
  return "Healthcheck details$extra";
}

sub content {
  ## @return HTML to be displayed
  my $self = shift;

  my $object  = $self->object;
  my $hub     = $self->hub;
  my $reports = $object->rose_objects('reports');
  my $param   = $object->view_param;
  my $type    = $object->view_type;
  my $rids    = $object->requested_reports;

  return $self->no_healthcheck_found(scalar @{$object->rose_objects('control_reports') || []}) unless $reports && @$reports;

  # if no filter selected, display the failure summary table for the given view type
  if (!$param && !@$rids) {
    return sprintf('<p>Click on a %s to view details</p>%s', $object->view_title, $self->failure_summary_table({
      'count'         => $self->group_report_counts($reports, [$type])->{$type},
      'type'          => $type,
      'session_id'    => $object->last_session_id,
      'release'       => $object->requested_release,
      'default_list'  => $object->get_default_list
    }));
  }

  my $html    = '';
  my $db_list = [];

  #group all reports by database_name
  my $grouped_reports = {};
  push @{$grouped_reports->{$_->database_name} ||= []}, $_ for @$reports;

  my $serial_number = 0;

  if ($type ne 'database_name') {
    my $form = $self->get_all_releases_dropdown_form('View in release', 'release');
    $form->add_hidden({'name' => '1', 'value' => $param});
    $html .= $form->render;
  }

  $html .= qq{<div class="_hc_infobox tinted-box">
    <p>For each database, reports are sorted on the basis of Date (initial failure date) with latest report appearing on the top.</p>
    <p>Reports that have not been annotated 'manual ok' are displayed in different colours for results <span class="hc-problem">problem</span>, <span class="hc-warning">warning</span> and <span class="hc-info">info</span>.</p>
    <p>Reports that appeared for the first time in the recent healthcheck session are in <span class="hc-new">bold</span> letters.</p>
  </div>};

  my $js_ref = 0; #counter used by JavaScript only
  foreach my $database_name (sort keys %$grouped_reports) {
  
    $js_ref++;
    my $table = $self->new_table([], [], {'class' => 'tint'});
    
    $table->add_columns(#note - use the space properly, we have too much to display in annotation and text columns
      {'key' => 'db_sp_tc', 'title' => $self->_get_first_column($object->function), 'width' => qq(20%)},
      {'key' => 'type',     'title' => 'Type',                                      'width' => '20px' },
      {'key' => 'text',     'title' => 'Text',                                      'width' => qq(40%)},
      {'key' => 'comment',  'title' => 'Annotation',                                'width' => qq(40%)},
      {'key' => 'team',     'title' => 'Team/person responsible',                   'width' => '100px'},
      {'key' => 'created',  'title' => 'Initial Failure Date',                      'width' => '60px' },
    );
    
    #sort reports on the basis of creation time 
    my $i = 0;
    my $db_reports = [];
    my $temp = { map { ($_->created || '0').++$i => $_ } @{$grouped_reports->{$database_name}} };
    push @$db_reports, $temp->{$_} for reverse sort keys %$temp;

    foreach my $report (@$db_reports) {
      my $report_id  = $report->report_id;
      my $result     = $report->result;
      my $db_sp_tc   = [];
      for (qw(database_type species testcase)) {
        next if $_ eq $type;
        push @$db_sp_tc, $self->get_healthcheck_link({'type' => $_, 'param' => ucfirst($report->$_), 'release' => $object->requested_release, 'cut_long' => 'cut'});
      }

      #annotation column
      my $annotation    = '';
      if ($report->annotation) {
        $annotation    .= $report->annotation->comment if $report->annotation->comment;
        my $modified_by = '';
        my $created_by  = '';
        if ($report->annotation->created_by) {
          $created_by  .= '<div class="hc-comment-info">Added by: '.$self->_get_user_link($report->annotation->created_by_user);
          $created_by  .= ' on '.$self->hc_format_date($report->annotation->created_at) if $report->annotation->created_at;
          $created_by  .= '</div>';
        }
        if ($report->annotation->modified_by) {
          $modified_by .= '<div class="hc-comment-info">Modified by: '.$self->_get_user_link($report->annotation->modified_by_user);
          $modified_by .= ' on '.$self->hc_format_date($report->annotation->modified_at) if $report->annotation->modified_at;
          $modified_by .= '</div>';
        }
        (my $temp       = $created_by) =~ s/Added/Modified/;
        $modified_by    = '' if $modified_by eq $temp;
        $annotation    .= $created_by.$modified_by;
        $annotation    .= '<div class="hc-comment-info">Action: '.$self->annotation_action($report->annotation->action)->{'title'}.'</div>'
          if $report->annotation->action && $self->annotation_action($report->annotation->action)->{'value'} ne '';
      }
      my $temp          = $report->annotation ? $report->annotation->action || '' : '';
      my $text_class    = $temp =~ /manual_ok|healthcheck_bug/ ? 'hc-oked' : sprintf('hc-%s', lc $result);
      $text_class      .= $report->first_session_id == $report->last_session_id ? ' hc-new' : ' hc-notnew';

      my $link_class    = join ' ', keys %{{ map { $_."-link" => 1 } split (' ', $text_class)}};

      $annotation      .= sprintf qq(<div class="hc-comment-link"><a class="$link_class" href="%s" rel="$js_ref">%s</a></div>),
        $hub->url({'action' => 'Annotation', 'rid' => $report_id}),
        $annotation eq '' ? 'Add&nbsp;Annotation' : 'Edit'
      ;

      $table->add_row({
        'db_sp_tc'  => join ('<br />', @$db_sp_tc),
        'comment'   => $annotation,
        'type'      => sprintf('<abbr title="%s">%s</abbr>', ucfirst lc $result, substr($result, 0, 1)),
        'text'      => qq(<span class="$text_class">).join (', ', split (/,\s?/, $report->text)).'</span>', #split-joining is done to wrap long strings
        'created'   => $report->created ? $self->hc_format_compressed_date($report->created) : '<i>unknown</i>',
        'team'      => join ', ', map { $self->get_healthcheck_link({'type' => 'team_responsible', 'param' => $_, 'release' => $object->requested_release}) } split(/\s*and\s*/, lc $report->team_responsible),
      });
    }

    $html .= sprintf('<a name="%s"></a><h3 class="hc-dbheading">%1$s</h3>%s', $database_name || 'Unknown', $table->render);
    push @$db_list, $database_name || 'Unknown';
  }

  return sprintf('%s%s', $object->function eq 'Database' ? '' : sprintf('<h3>List of affected databases:</h3><ul>%s</ul>', join('', map {sprintf('<li><a href="#%s">%1$s</a></li>', $_)} @$db_list)), $html);
}

sub _get_user_link {
  ## private helper method to print a link for the user with his email
  my ($self, $user) = @_;
  return sprintf('<a href="mailto:%s">%s</a>', $user->email, $user->name) if $user;
  return 'unknown user';
}

sub _get_first_column {
  ## private helper method to give the first column of the table for a given view type
  return {
    'Database'  => 'DB Type<br />Species<br />Testcase',
    'DBType'    => 'Species<br />Testcase',
    'Species'   => 'Database Type<br />Testcase',
    'Testcase'  => 'Database Type<br />Species',
    'Team'      => 'DB Type<br />Species<br />Testcase',
  }->{$_[-1]};
}


1;

package EnsEMBL::Admin::Component::Healthcheck;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

use Rose::DateTime::Util qw(format_date parse_date);

use constant {
  FIRST_RELEASE_FOR_HEALTHCHECK => 42,   #healthchecks started from release 42
  NO_HEALTHCHECK_FOUND          => '<p class="hc_p">Healthchecks have not been performed for this release.</p>',
};

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub caption {
  return '';
}

sub _get_default_list {
  my ($self, $view, $report_db_interface, $first_session_id) = @_;
  my $list = [];
  if ($view =~ /^testcase|database_name$/) {
    my $query = $view =~ 'testcase' ? 'fetch_for_distinct_testcases' : 'fetch_for_distinct_databases';
    $list = [ keys %{{ map {$_->$view => 1} @{$report_db_interface->$query({'session_id' => $first_session_id, 'include_all' => 1}) || []} }} ];
  }
  elsif ($view eq 'species') {
    $list = $self->hub->species_defs->ENSEMBL_DATASETS || [];
  }
  elsif ($view eq 'database_type') {
    $list = [qw(cdna core funcgen otherfeatures production variation vega)];
  }
  return $list;
}

sub render_all_releases_selectbox {
  ## Returns an HTML selectbox with all possible releases for healthchecks as options
  ## $skip - release to be skipped in the select box

  my ($self, $skip) = @_;

  my $current       = $self->hub->species_defs->ENSEMBL_VERSION;
  my $html          = qq(<select name="release">);
    for (my $count  = $current; $count >= FIRST_RELEASE_FOR_HEALTHCHECK; $count--) {
      next if defined $skip && $count == $skip;
      $html        .= qq(<option value="$count">Release $count</option>);
    }
    $html          .= qq(</select>);
    return $html;
}

sub validate_release {
  ## Validates whether or not the given release have healthchecks

  my ($self, $release)  = @_;
  my $current           = $self->hub->species_defs->ENSEMBL_VERSION;
  return $release >= $self->FIRST_RELEASE_FOR_HEALTHCHECK && $release <= $current;

}

sub get_healthcheck_link {
  ## Returns a formatted link for healthcheck page depending upon following keys
  ## params keys 
  ##  - type: view type of the link eg. species, testcase etc.
  ##  - param: value of the filter parameter
  ##  - caption: caption to be displayed
  ##  - title: goes in title attribute
  ##  - release: release id
  ##  - cut_long: flag stating whether or not to cut the long caption of the link

  my ($self, $params) = @_;
  
  my $caption = exists $params->{'caption'} && defined $params->{'caption'} ? $params->{'caption'} : '';
  $caption = $params->{'param'} || '<i>unknown</i>' if $caption eq '';
  return $caption unless $params->{'param'};

  my $title   = $params->{'title'} || $caption;
  my $param   = $params->{'param'};
  my $release = $params->{'release'};
  $caption    = substr($caption, 0, 20).'&#133;'
    if exists $params->{'cut_long'} && $params->{'cut_long'} eq 'cut' && length $caption > 23;

  if ($params->{'type'} eq 'species') {
    my $all_species = { map {$_ => 1} @{ $self->builder->hub->species_defs->ENSEMBL_DATASETS || [] } }; #species validation
    return $caption unless exists $all_species->{ $param };
    return qq(<a href="/$param/Healthcheck/Species?release=$release" title="List all failed test reports for Speices $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'testcase') {
    return qq(<a href="/Healthcheck/Testcase?release=$release;test=$param" title="List all failed test reports for Testcase $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_type') {
    return qq(<a href="/Healthcheck/DBType?release=$release;db=$param" title="List all failed test reports for Database Type $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_name') {
    return qq(<a href="/Healthcheck/Database?release=$release;db=$param" title="List all failed test reports for Database Name $title in release $release">$caption</a>);
  }
  else {
    return $caption;
  }
}

sub hc_format_date {
  ## Formates date for displaying
  my ($self, $datetime) = @_; 
  return format_date(parse_date($datetime), "%b %e, %Y at %H:%M");
}

sub hc_format_compressed_date {
  ## Formates date for displaying the HC table column
  my ($self, $datetime) = @_; 
  return format_date(parse_date($datetime), "%d/%m/%y %H:%M");  
}

sub space_before_capitals {
  ## Converts "SpaceBeforeCapitals" to "Space Before Capitals"
  my ($self, $string) = @_;
  return '' unless defined $string && $string ne '';
  $string =~ s/\b(\w)/\u$1/g;
  $string =~ s/ //;
  return join (' ', split (/(?=[A-Z]{1}[^A-Z]*)/, $string));
}

sub annotation_action {
  ## Returns a label for the action enums for annotation.
  my ($self, $value) = @_;
  
  my $action = {
    'manual_ok'                 => 'Manual ok: not a problem for this release',
    'under_review'              => 'Under review: Fixed or will be fixed/reviewed',
    'note'                      => 'Note or comment',
    'healthcheck_bug'           => 'Healthcheck bug: error should not appear, requires changes to healthcheck',
    'manual_ok_all_releases'    => 'Manual ok all release: not a problem for this species',
    'manual_ok_this_assembly'   => 'Manual ok this assembly: not a problem for this species and assembly',
    'manual_ok_this_genebuild'  => 'Manual ok this assembly: not a problem for this genebiuld',
  };
  
  return $action if $value eq 'all';
  
  return exists $action->{ $value }
    ? {'value' => $value,  'title' => $action->{ $value }}
    : {'value' => '',      'title' => ''};
}

sub content_failure_summary {
  ## Returns a filure summary table for given view types
  ## Params Hashref with keys:
  ##  - view                Species, Testcase etc
  ##  - last_session_id     Id of the session run most recently in the given release
  ##  - first_session_id    Id of the first session run in the given release
  ##  - release             release id
  ##  - all_reports         ArrayRef of all Report objects
  ##  - release2            release id of the release to which reports are to be compared
  ##  - compare_reports     ArrayRef of all Report objects for release2
  ##  - report_db_interface Report db interface object
  my ($self, $params) = @_; 
    
  my $table = $self->new_table();

  (my $perspective = ucfirst($params->{'view'})) =~ s/_/ /g;

  $table->add_columns(
    { 'key' => 'group',         'title' => $perspective, 'width' => qq(40%) },
    { 'key' => 'new_failed',    'title' => "Newly failed for last run (Session $params->{'last_session_id'} in v$params->{'release'})",  'align' => 'center' },
    { 'key' => 'total_failed',  'title' => "All failed for last run (v$params->{'release'})",    'align' => 'center' },
  );

  $table->add_columns(#add 4th column if comparison is intended
    { 'key' => 'comparison',  'title' => "Failed in  release $params->{'release_2'}", 'align' => 'center' },
  ) if exists $params->{'compare_reports'};

  my $fails             = $self->_group_fails($params->{'all_reports'}, $params->{'view'});
  my $fails_2           = exists $params->{'compare_reports'} ? $self->_group_fails($params->{'compare_reports'}, $params->{'view'}) : {};
  my $default_list      = { map {$_ => 1} @{ $self->_get_default_list($params->{'view'}, $params->{'report_db_interface'}, $params->{'first_session_id'})} };
  my $groups            = { %$default_list, %$fails, %$fails_2};

  for ( sort keys (%$groups) ) {

    my $title = $params->{'view'} eq 'species' ? ucfirst($_) : $_;

    my $fourth_cell     = exists $params->{'compare_reports'} ? {
      'comparison'  => $self->get_healthcheck_link({
        'type'        => $params->{'view'},
        'param'       => $title,
        'caption'     => $fails_2->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $params->{'release_2'}
      })
    } : {};
    $table->add_row({
      'group'       => $self->get_healthcheck_link({
        'type'        => $params->{'view'},
        'param'       => $title,
        'release'     => $params->{'release'}
      }),
      'new_failed'  => $fails->{ $_ }{'new_fails'} || '0',
      'total_failed'  => $self->get_healthcheck_link({
        'type'        => $params->{'view'},
        'param'       => $title,
        'caption'     => $fails->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $params->{'release'}
      }),
      %$fourth_cell
    });
  }
  return $table->render;
}

sub _group_fails {
  ## generates stats for reports for new failures and all failures
  ## returns HashRef {$group_name => {'new_fails' => ?, 'total_fails' => ?}}
  my ($self, $reports, $view) = @_;
  my $fails = {};

  for (@$reports) {
    next unless defined $_->$view;
    my $key = $view eq 'species' ? ucfirst($_->$view) : $_->$view; #coz species should have first letter capital, but in hc.report db table it is all lower case.
    $fails->{ $key } = {'new_fails' => 0, 'total_fails' => 0} unless exists $fails->{ $key };
    $fails->{ $key }{'total_fails'}++;
    $fails->{ $key }{'new_fails'}++    if $_->first_session_id == $_->last_session_id;
  }
  return $fails;
}

1;
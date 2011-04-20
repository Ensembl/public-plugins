package EnsEMBL::Admin::Component::Healthcheck;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

use Rose::DateTime::Util qw(format_date parse_date);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub caption {
  return '';
}

sub no_healthcheck_found {
  ## @return Text to be displayed in case no healthcheck found
  my $self   = shift;
  my $object = $self->object;
  return '<p class="hc_p">Healthchecks have not been performed for this release.</p>' unless $object->requested_release;
  my $extra  = $object->view_type && $object->view_param ? sprintf(" for %s '%s'", $object->view_title, $object->view_param) : '';
  return qq(<p class="hc_p">No healthcheck reports found$extra.</p>);
}

sub render_all_releases_selectbox {
  ## Returns an HTML selectbox with all possible releases for healthchecks as options
  my $self = shift;
  
  my $object = $self->object;
  my $first  = $object->first_release;
  my $last   = $object->current_release;
  my $skip   = $object->requested_release;

  my @options;
  defined $skip && $_ == $skip or unshift @options, qq(<option value="$_">Release $_</option>) for $first..$last;
  return '<select name="release">'.join('', @options).'</select>';
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
  ##  - class: Class attribute
  my ($self, $params) = @_;

  my $caption = exists $params->{'caption'} && defined $params->{'caption'} ? $params->{'caption'} : '';
  $caption = $params->{'param'} || '<i>unknown</i>' if $caption eq '';
  return $caption unless $params->{'param'};

  my $title   = $params->{'title'} || $caption;
  my $param   = $params->{'param'};
  my $release = $params->{'release'};
  $caption    = substr($caption, 0, 20).'&#133;'
    if exists $params->{'cut_long'} && $params->{'cut_long'} eq 'cut' && length $caption > 23;
    
  my $class = $params->{'class'} ? qq( class="$params->{'class'}") : '';
  
  if ($params->{'type'} eq 'species') {
    return $caption unless $self->object->validate_species($param);
    return qq(<a$class href="/$param/Healthcheck/Details/Species?release=$release" title="List all failed test reports for Speices $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'testcase') {
    return qq(<a$class href="/Healthcheck/Details/Testcase?release=$release;q=$param" title="List all failed test reports for Testcase $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_type') {
    return qq(<a$class href="/Healthcheck/Details/DBType?release=$release;q=$param" title="List all failed test reports for Database Type $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'database_name') {
    return qq(<a$class href="/Healthcheck/Details/Database?release=$release;q=$param" title="List all failed test reports for Database Name $title in release $release">$caption</a>);
  }
  elsif ($params->{'type'} eq 'team_responsible') {
    $param   = lc $param;
    $title   = join(' ', map {ucfirst lc $_} split('_', $param));
    $caption = exists $params->{'caption'} ? $params->{'caption'} : $title;
    return qq(<a$class href="/Healthcheck/Details/Team?release=$release;q=$param" title="List all failed test reports for Team $title in release $release">$caption</a>);
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
  ##  - type                species, testcase, database_name etc
  ##  - session_id          Id of the session run most recently in the given release
  ##  - release             release id
  ##  - reports             ArrayRef of all Report objects
  ##  - default_list        ArrayRef of default list of Testcases, DBTypes, Species or Databases as required
  ##  - release2            release id of the release to which reports are to be compared
  ##  - compare_reports     ArrayRef of all Report objects for release2
  my ($self, $params) = @_; 
    
  (my $title  = ucfirst($params->{'type'})) =~ s/_/ /g;
  my $table   = $self->new_table();

  $table->add_columns(
    { 'key' => 'group',         'title' => $title, 'width' => qq(40%) },
    { 'key' => 'new_failed',    'title' => "Newly failed for last run (Session $params->{'session_id'} in v$params->{'release'})",  'align' => 'center' },
    { 'key' => 'total_failed',  'title' => "All failed for last run (v$params->{'release'})",    'align' => 'center' },
  );

   $table->add_columns(#add 4th column if comparison is intended
     { 'key' => 'comparison',  'title' => "Failed in  release $params->{'release2'}", 'align' => 'center' },
   ) if exists $params->{'compare_reports'};

  my $fails   = $self->_group_fails($params->{'reports'}, $params->{'type'});
  my $fails_2 = exists $params->{'compare_reports'} ? $self->_group_fails($params->{'compare_reports'}, $params->{'type'}) : {};
  my $groups  = { %$fails, %$fails_2, map {$_ => 1} @{$params->{'default_list'}} };

  for (sort keys %$groups) {

    $title = $params->{'type'} eq 'species' ? ucfirst($_) : $_;

    my %fourth_cell = exists $params->{'compare_reports'} ? (
      'comparison'  => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $title,
        'caption'     => $fails_2->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $params->{'release2'}
      })
    ) : ();
    $table->add_row({
      'group'       => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $title,
        'release'     => $params->{'release'}
      }),
      'new_failed'  => $fails->{ $_ }{'new_fails'} || '0',
      'total_failed'  => $self->get_healthcheck_link({
        'type'        => $params->{'type'},
        'param'       => $title,
        'caption'     => $fails->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $params->{'release'},
        'class'       => $fails->{ $_ }{'total_fails'} ? 'hc-failsrow' : 'hc-nofailsrow',
      }),
      %fourth_cell
    });
  }
  return $table->render;
}

sub _group_fails {
  ## generates stats for reports for new failures and all failures
  ## @return HashRef {$name => {'new_fails' => ?, 'total_fails' => ?}}
  my ($self, $reports, $type) = @_;
  my $fails = {};

  for (@$reports) {
    next unless defined $_->$type;
    my $key = $type eq 'species' ? ucfirst($_->$type) : $_->$type; #coz species should have first letter capital, but in hc.report db table it is all lower case.
    $fails->{ $key } = {'new_fails' => 0, 'total_fails' => 0} unless exists $fails->{ $key };
    $fails->{ $key }{'total_fails'}++;
    $fails->{ $key }{'new_fails'}++ if $_->first_session_id == $_->last_session_id;
  }
  return $fails;
}

1;
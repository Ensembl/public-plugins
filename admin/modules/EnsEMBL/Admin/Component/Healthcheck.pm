package EnsEMBL::Admin::Component::Healthcheck;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component);

use Rose::DateTime::Util qw(format_date parse_date);

use constant {
  FIRST_RELEASE_FOR_HEALTHCHECK => 42,   #healthchecks started from release 42
  NO_HEALTHCHECK_FOUND          => 'Healthcheck has not been performed for this release',
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
  return [];
}

sub render_all_releases_selectbox {
  
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

  my ($self, $release)  = @_;
  my $current           = $self->hub->species_defs->ENSEMBL_VERSION;
  return $release >= $self->FIRST_RELEASE_FOR_HEALTHCHECK && $release <= $current;

}

sub get_healthcheck_link {
  ##params keys - type, param, caption, title, release, cut_long

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

  my ($self, $datetime) = @_; 
  return format_date(parse_date($datetime), "%b %e, %Y at %H:%M");
}

sub hc_format_compressed_date {

  my ($self, $datetime) = @_; 
  return format_date(parse_date($datetime), "%d/%m/%y %H:%M");  
}

sub space_before_capitals {

  my ($self, $string) = @_;
  return '' unless defined $string && $string ne '';
  $string =~ s/\b(\w)/\u$1/g;
  $string =~ s/ //;
  return join (' ', split (/(?=[A-Z]{1}[^A-Z]*)/, $string));
}

sub annotation_action {

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
  
  my ($self, $view, $last_session_id, $release, $all_reports, $release_2, $compare_reports) = @_;
  
  my $table = $self->new_table();

  (my $perspective = ucfirst($view)) =~ s/_/ /g;

  $table->add_columns(
    { 'key' => 'group',       'title' => $perspective, 'width' => qq(40%) },
    { 'key' => 'new_failed',  'title' => "Newly failed for last run (Session $last_session_id in v$release)",  'align' => 'center' },
    { 'key' => 'results',     'title' => "All failed for last run (v$release)",    'align' => 'center' },
  );

  $table->add_columns(#add 4th column if comparison is intended
    { 'key' => 'comparison',  'title' => "Failed in  release $release_2", 'align' => 'center' },
  ) if defined $compare_reports;

  my $fails             = $self->_group_fails($all_reports, $view);
  my $fails_2           = defined $compare_reports ? $self->_group_fails($compare_reports, $view) : {};
  my $default_list      = { map {$_ => 1} @{ $self->_get_default_list || [] } }; #will work only for view specific pages
  my $groups            = { %$default_list, %$fails, %$fails_2};

  for ( sort keys (%$groups) ) {

    my $title = $view eq 'species' ? ucfirst($_) : $_;

    my $fourth_cell     = defined $compare_reports ? {
      'comparison'  => $self->get_healthcheck_link({
        'type'        => $view,
        'param'       => $title,
        'caption'     => $fails_2->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $release_2
      })
    } : {};
    $table->add_row({
      'group'       => $self->get_healthcheck_link({
        'type'        => $view,
        'param'       => $title,
        'release'     => $release
      }),
      'new_failed'  => $fails->{ $_ }{'new_fails'} || '0',
      'results'     => $self->get_healthcheck_link({
        'type'        => $view,
        'param'       => $title,
        'caption'     => $fails->{ $_ }{'total_fails'} || '0',
        'title'       => $title,
        'release'     => $release
      }),
      %$fourth_cell
    });
  }
  return $table->render;
}

sub _group_fails {

  my ($self, $reports, $view)  = @_;
  my $fails             = {}; #{group_name => {new_fails => ?, total_fails => ?}}

  for (@$reports) {
    next unless defined $_->$view ;
    my $key = $view eq 'species' ? ucfirst($_->$view) : $_->$view; #fix -  species should have first letter capital, but in hc.report table it is all lower case.
    $fails->{ $key } = {'new_fails' => 0, 'total_fails' => 0} unless exists $fails->{ $key };
    $fails->{ $key }{'total_fails'}++;
    $fails->{ $key }{'new_fails'}++    if $_->first_session_id == $_->last_session_id;
  }
  return $fails;
}

1;
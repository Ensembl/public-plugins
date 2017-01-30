=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Admin::Component::Healthcheck::HealthcheckBugs;

use strict;
use warnings;

use parent qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption { return ''; }

sub content {
  ## @return HTML to be displayed
  my $self = shift;

  my $object  = $self->object;
  my $hub     = $self->hub;
  my $reports	= $object->rose_objects('hc_bug_reports') || [];
  my $table   = $self->new_table([
    {'key' => 'reports',    'title' => 'Report(s)',         'sort' => 'html',         'width' => q(35%)},
    {'key' => 'annotation', 'title' => 'Annotation',        'sort' => 'html',         'width' => q(30%)},
    {'key' => 'time',       'title' => 'Last annotated at', 'sort' => 'html_numeric', 'width' => q(10%)},
    {'key' => 'user',       'title' => 'Reported by',       'sort' => 'html',         'width' => q(15%)},
    {'key' => 'count',      'title' => 'Number of reports', 'sort' => 'numeric',      'width' => q(10%)}
  ], [], {'data_table' => 1});

  unless ($reports && @$reports) {
    return sprintf q(<p>No anntations marked as 'healthcheck_bug' found for release %s.%s</p>),
      $object->requested_release,
      $self->get_all_releases_dropdown_form('View in release', 'release')->render;
  }

  my %healthcheck_bugs;

  for (@$reports) {
    my $annotation    = $_->annotation;
    my $annotated_at  = $annotation->created_at;
    my $entry         = $healthcheck_bugs{$annotation->comment} ||= {};

    if (!$entry->{'annotated_at'} || $annotated_at && $entry->{'annotated_at'}->epoch < $annotated_at->epoch) {
      $entry->{'annotated_at'} = $annotated_at;
    }

    push @{$entry->{'reports'} ||= []}, $_;
  }

  while (my ($annotation_comment, $entry) = each %healthcheck_bugs) {

    my (@report_texts, @report_ids, @annotators);

    for (@{$entry->{'reports'}}) {
      push @report_ids,   $_->report_id;
      push @annotators,   $_->created_by_user || (), $_->modified_by_user || () for $_->annotation;
      push @report_texts, sprintf('<li>%s&nbsp;<span class="small">[<a href="%s">Edit annotation</a>]</span></li>', $_->text, $hub->url({'action' => 'Annotation', 'rid' => $_->report_id}));
    }

    $annotation_comment = sprintf(
      '%s <span class="small">[<a href="%s">Edit</a>] [<a href="%s">View reports</a>]</span>',
      $annotation_comment,
      $hub->url({'action' => 'Annotation', 'rid' => join ',', @report_ids}),
      $hub->url({'action' => 'Details', 'function' => 'Testcase', 'rid' => join ',', @report_ids})
    );

    $table->add_row({
      'reports'     => sprintf('<ul>%s</ul>', join '', @report_texts),
      'annotation'  => $annotation_comment,
      'time'        => $self->_annotated_at_field($entry->{'annotated_at'}),
      'user'        => join(' ', map { sprintf('<a href="mailto:%s">%s</a>', $_->email, $_->name) } values %{{ map { $_->user_id => $_ } @annotators }}),
      'count'       => scalar @{$entry->{'reports'}}
    });
  }

  return $table->render;
}

sub _annotated_at_field {
  my ($self, $datetime) = @_;
  return sprintf '<input type="hidden" value="%s" />%s', $datetime ? ($datetime->epoch, $self->hc_format_compressed_date($datetime)) : (0, '');
}

1;

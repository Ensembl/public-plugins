=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::IDMapper::Results;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::IDMapper);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $job     = $object->get_requested_job({'with_all_results' => 1});

  return '' unless $job;

  my $columns = [
    {'key' => 'old',      'title' => 'Old stable ID'  },
    {'key' => 'new',      'title' => 'New stable ID'  },
    {'key' => 'release',  'title' => 'Release',       'sort' => 'numeric' },
  ];

  # convert column value to displayable format for each column in each row's hash
  my @rows = map { my $row = $_; $row = { map { $_ => $self->_decorate($row, $_) } keys %$row } } map $_->result_data->raw, $job->result;

  return @rows ? $self->new_table($columns, \@rows, {'data_table' => 1})->render : $self->_warning('No results', 'No stable IDs mapped to the given IDs');
}

sub _decorate {
  my ($self, $row, $col) = @_;

  my $val = $row->{$col};

  if ($col eq 'new') {
    my $url = $self->object->get_stable_id_link($val, $row->{'release'});
    $val = $url ? sprintf '<a href="%s">%s</a>', $self->hub->url($url), $val : $val;

  } else {
    $val = $self->html_encode($val);
  }

  return $val;
}

1;

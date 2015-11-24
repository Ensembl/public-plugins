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
  my $current = $hub->species_defs->ENSEMBL_VERSION;

  return '' unless $job;

  my $columns = [
    {'key' => 'id',       'title' => 'Requested ID',  'width' => '40%' },
    {'key' => 'new',      'title' => 'Matched ID(s)', 'width' => '40%' },
    {'key' => 'release',  'title' => 'Releases',      'width' => '20%', 'sort' => 'none'},
  ];

  my @rows;

  foreach my $old_id (map $_->result_data->raw, $job->result) {

    my %ids;

    for (@{$old_id->{'mappings'}}) {
      my ($release, $new_id, $version);

      ($release, $new_id) = @$_;
      ($new_id, $version) = split /\./, $new_id;

      $ids{$new_id}{$release} = $version;
    }

    # if the ID is not retired, update the current release version to the latest version
    if (exists $ids{'<retired>'}) {
      delete $ids{'<retired>'};
    } else {
      for (keys %ids) {
        my ($latest_release) = reverse sort keys %{$ids{$_}};
        $ids{$_}{$current} = delete $ids{$_}{$latest_release};
      }
    }

    foreach my $new_id (keys %ids) {
      push @rows, {
        'id'      => $self->html_encode($old_id->{'id'}),
        'new'     => $self->html_encode($new_id),
        'release' => join '', map sprintf('<p><b>%s</b>: %s</p>', $_, $self->_decorate($new_id, $ids{$new_id}{$_}, $_)), sort {$b <=> $a} keys %{$ids{$new_id}}
      };
    }
  }

  return @rows ? $self->new_table($columns, \@rows, {'data_table' => 1})->render : $self->_warning('No results', 'No stable IDs mapped to the given IDs');
}

sub _decorate {
  my ($self, $id, $version, $release) = @_;

  my $url = $self->object->get_archive_link($id, $release);
  $id     = $self->html_encode("$id.$version");

  return $url ? sprintf '<a href="%s">%s</a>', $url, $id : $id;
}

1;

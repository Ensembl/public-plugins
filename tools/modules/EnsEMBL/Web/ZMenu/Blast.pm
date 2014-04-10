=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ZMenu::Blast;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object->get_sub_object;
  my $coord_range = $hub->param('bin');
  my $index       = $hub->param('idx') || 0;
  my $job         = $object->get_requested_job({'with_requested_result' => 1});
  my $hits        = {};

  my ($hit, $hit_id);

  if ($job) {

    my $result = $job->result->[0];
    $hit_id = $result->result_id;
    $hit    = $result->result_data;

  } else {

    $job    = $object->get_requested_job; # ignore the result here since it did not return anything in the previous attempt
    $hits   = $object->get_all_hits_by_coords($job) if $job;

    return unless $job && keys %$hits;

    $hit_id = [ sort { $hits->{$b}->{'score'} <=> $hits->{$a}->{'score'} } keys %$hits ]->[ $index ];
    $hit    = $hits->{$hit_id};
  }

  $self->caption('Blast/Blat Hit');
  $self->highlight("hsp_$hit_id");

  $self->add_entry({ 'type' => 'Query bp',    'label' => sprintf('%s:%s-%s', $hit->{'qid'}, $hit->{'qstart'}, $hit->{'qend'}) });
  $self->add_entry({ 'type' => 'Target',      'label' => $hit->{'tid'}                                                        }) if $hit->{'db_type'} !~/latest/i;
  $self->add_entry({ 'type' => 'Genomic bp',  'label' => sprintf('%s:%s-%s', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}) });
  $self->add_entry({ 'type' => 'Score',       'label' => $hit->{'score'}                                                      });
  $self->add_entry({ 'type' => 'E-value',     'label' => $hit->{'evalue'}                                                     });
  $self->add_entry({ 'type' => '%ID',         'label' => $hit->{'pident'}                                                     });
  $self->add_entry({ 'type' => 'Length',      'label' => $hit->{'len'}                                                        });

  if ($hits && keys %$hits > 1) {

    $self->pagination({
      'position'      => $index,
      'total'         => keys %$hits,
      'url_template'  => $hub->url({
        'type'          => 'ZMenu',
        'action'        => 'Blast',
        'function'      => '',
        'tl'            => $object->create_url_param({'result_id' => $hit_id}),
        'bin'           => $coord_range,
        'idx'           => 1
      })
    });

  }
}

1;

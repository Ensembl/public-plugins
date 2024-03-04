=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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
  my $self          = shift;
  my $hub           = $self->hub;
  my $object        = $self->object->get_sub_object('Blast');
  my $job           = $object->get_requested_job({'with_all_results' => 1});
  my $job_data      = $job->job_data;
  my $species       = $job->species;
  my %required_hits = map {$_ => 1} split ',', $hub->param('hit') || ''; # for overlapping result hits on karyotype
  my @results       = grep { $required_hits{$_->result_id} } $job->result;
  my $blast_type    = $object->parse_search_type($job_data->{'search_type'}, 'blast_type') eq 'BLAT' ? 'BLAT' : 'BLAST';

  $self->header(sprintf '%s %s hits', scalar @results, $blast_type) if @results > 1;

  for (sort { $b->result_data->{'pident'} <=> $a->result_data->{'pident'} } @results) {

    $self->new_feature;
    $self->add_hit_content($job, $_, $blast_type, @results > 1);

  }
}

sub add_hit_content {
  my ($self, $job, $result, $blast_type, $multiple) = @_;

  my $hub     = $self->hub;
  my $object  = $self->object->get_sub_object('Blast');
  my $hit     = $result->result_data;
  my $urls    = $object->get_result_urls($job, $result);

  $self->caption($multiple ? sprintf '%s:%s-%s', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'} : "$blast_type hit");
  $self->highlight(sprintf 'hsp_%s', $result->result_id);

  $self->add_entry({
    'type'        => 'Genomic bp',
    'label_html'  => sprintf('%s:<wbr>%s-<wbr>%s', $hit->{'gid'}, $hit->{'gstart'}, $hit->{'gend'}),
    'link'        => $hub->url($urls->{'location'})
  });

  $self->add_entry({
    'type'        => 'Query bp',
    'label_html'  => sprintf('%s:<wbr>%s-<wbr>%s', $hit->{'qid'}, $hit->{'qstart'}, $hit->{'qend'})
  });

  $self->add_entry({
    'type'        => 'Target',
    'label'       => $hit->{'tid'},
    'link'        => $hub->url($urls->{'target'})
  }) if $urls->{'target'};

  $self->add_entry({
    'type'        => $job->job_data->{'source'} =~/latestgp/i ? 'Overlapping Gene(s)' : 'Gene hit',
    'label_html'  => join(', ', map { sprintf '<a href="%2$s">%1$s</a>', delete $_->{'label'}, $hub->url($_) } @{$urls->{'gene'}})
  }) if @{$urls->{'gene'}};

  $self->add_entry({ 'type' => 'Score',   'label' => $hit->{'score'}  });
  $self->add_entry({ 'type' => 'E-value', 'label' => $hit->{'evalue'} });
  $self->add_entry({ 'type' => '%ID',     'label' => $hit->{'pident'} });
  $self->add_entry({ 'type' => 'Length',  'label' => $hit->{'len'}    });

  # Alignment and sequence links
  for (qw(alignment query_sequence genomic_sequence)) {
    $self->add_entry({ 'label_html' => sprintf('<a href="%s" class="_ht">%s</a>', $hub->url($urls->{$_}), ucfirst $_ =~ s/_/ /r) });
  }
}

1;

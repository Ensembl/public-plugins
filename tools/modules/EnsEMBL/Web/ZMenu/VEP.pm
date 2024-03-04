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

package EnsEMBL::Web::ZMenu::VEP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $hub->core_object('Tools') or return;
     $object    = $object->get_sub_object('VEP');
  my $job       = $object->get_requested_job({'with_requested_result' => 1}) or return;
  my $variant   = $job->result->[0]->result_data->raw;
  my $loc       = sprintf('%s:%s-%s', $variant->{'chr'}, $variant->{'start'}, $variant->{'end'});

  $self->caption(sprintf 'Variant: %s', $variant->{'variation_name'});

  $self->add_entry({
    'type'        => 'Location',
    'label_html'  => sprintf('%s<a href="%s" class="_location_mark hidden"></a>',
      $variant->{'start'} == $variant->{'end'} ? sprintf('%s:%s', $variant->{'chr'}, $variant->{'start'}) : $loc,
      $hub->url({ 'species' => $job->species, 'type' => 'Location', 'action' => 'View', 'r' => $loc })
    )
  });

  $self->add_entry({
    'type'        => 'Consequence',
    'label_html'  => $self->variant_consequence_label($variant->{'consequence_type'})
  });

  $self->add_entry({
    'type'  => 'Allele string',
    'label' => $variant->{'allele_string'}
  });

  $self->add_entry({
    'label' => 'Go to results page',
    'link'  => $hub->url({'type' => 'Tools', 'action' => 'VEP', 'function' => 'Results', 'tl' => $object->create_url_param({'result_id' => undef})})
  });
}

1;

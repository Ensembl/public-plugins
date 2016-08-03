=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein;

use strict;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::Alignment);

use EnsEMBL::Web::TextSequence::View::AlignmentProtein;

sub get_sequence_data_new {
  my ($self, $slices, $config) = @_;
  my $job         = $self->job;
  my $hit         = $self->hit;
  my $source_type = $job->job_data->{'source'};
  my (@markup, $object);
  
  $config->{'length'}        = $hit->{'len'}; 
  $config->{'Subject_start'} = $hit->{'tstart'};
  $config->{'Subject_end'}   = $hit->{'tend'};
  $config->{'Subject_ori'}   = $hit->{'tori'}; 
  $config->{'Query_start'}   = $hit->{'qstart'};
  $config->{'Query_end'}     = $hit->{'qend'};

  $config->{'source_type'} = $source_type;
  
  if ($self->blast_method eq 'TBLASTN') {
    $config->{'Subject_start'} = $hit->{'gori'} == 1 ? $hit->{'gstart'} : $hit->{'gend'};
    $config->{'Subject_end'}   = $hit->{'gori'} == 1 ? $hit->{'gend'}   : $hit->{'gstart'};
    $config->{'Subject_ori'}   = $hit->{'gori'};
  }
 
  $config->{'blast_method'} = $self->blast_method; 
  $config->{'transcript'} = undef;

  if ($source_type !~ /latestgp/i) { # Can't markup based on protein sequence as we only have a translated DNA region
    my $adaptor    = $self->hub->get_adaptor(sprintf('get_%sAdaptor', $source_type =~ /abinitio/i ? 'PredictionTranscript' : 'Translation'), 'core', $job->species);
    my $transcript = $adaptor->fetch_by_stable_id($hit->{'tid'});
     $transcript = $transcript->transcript unless $transcript->isa('Bio::EnsEMBL::Transcript');
     $object     = $self->new_object('Transcript', $transcript, $self->object->__data);
    $_->{'transcript'} = $object for(@$slices);
  }
  
  my $view = $self->view;
  $view->set_annotations($config);
  $view->prepare_ropes($config,$slices);
  my @sequences = @{$view->sequences};
  foreach my $slice (@$slices) {
    my $sequence = shift @sequences;
    my $seq = uc($slice->{'seq'} || $slice->{'slice'}->seq(1));
    my $mk  = {};
 
    $view->annotate_new($config,$slice,$mk,$seq,$sequence);
    push @markup, $mk;
  }

  return ([@{$view->sequences}], \@markup);
}

sub make_view {
  my $self = shift;
  return EnsEMBL::Web::TextSequence::View::AlignmentProtein->new(@_);
}

1;

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

package EnsEMBL::Web::Component::Tools::Blast::TextSequence;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::TextSequence
  EnsEMBL::Web::Component::Tools::Blast
);

use EnsEMBL::Web::TextSequence::Output::WebSubslice;
use EnsEMBL::Web::TextSequence::View::BLAST;

sub job            { return $_[0]{'_job'};                        } ## @return The cached requested job object
sub hit            { return $_[0]{'_hit'};                        } ## @return Result hit (hashref)
sub blast_method   { return $_[0]{'_blast_method'};               } ## @return Blast method chosen for the given job
sub is_protein     { return $_[0]{'_is_protein'};                 } ## @return Flag whether the sequence is protein or not
sub object         { return $_[0]->SUPER::object->get_sub_object; } ## Gets the actual blast object instead of the Tools object
sub get_slice_name { return $_[1]->name;                          }
sub blast_options  { return undef;                                } ## Don't display blast button for blast results

sub new {
  ## @override
  ## Adds hsp_display as a key param, info about the requested job and the blast method, and adds some extra keys to the objects after instantiating it
  my $self   = shift->SUPER::new(@_);
  my $object = $self->object;

  $self->{'_job'}               = $object->get_requested_job({ with_requested_result => 1 }) or return $self;
  $self->{'_blast_method'}      = $object->parse_search_type($self->{'_job'}->job_data->{'search_type'}, 'search_method');
  $self->{'_is_protein'}        = $self->{'_blast_method'} =~ /^(blastx|blastp)$/i ? 1 : 0;
  $self->{'_hit'}               = $self->{'_job'}->result->[0]->result_data->raw;
  $self->{'_hit'}{'result_id'}  = $self->{'_job'}->result->[0]->result_id;

  push @{$self->{'key_types'}},  'HSP';
  push @{$self->{'key_params'}}, 'hsp_display';

  return $self;
}

sub _init {
  ## @override
  ## Sets subslice length, and makes it not-cacheable
  my $self    = shift;
  my $hub     = $self->hub;
  my @package = split '::', ref $self;

  $self->{'view_config'} = $hub->get_viewconfig($package[-1], $package[-2], 'cache');

  $self->SUPER::_init(5000);
  $self->cacheable(0);
}

sub get_sequence_data {
  ## @override
  ## Add HSPs to the sequence data
  my ($self, $slices, $config) = @_;

  $config->{'hit'} = $self->hit;
  $config->{'job'} = $self->job;
  $config->{'object'} = $self->object;
  $config->{'slice_type'} = ref($self) =~ /QuerySeq$/ ? 'q' : 'g';
  my ($sequence, $markup) = $self->SUPER::get_sequence_data($slices, $config);

  return ($sequence, $markup);
}

sub content {
  my $self    = shift;
  my $slice   = $self->get_slice;
  my $length  = $slice->length;
  my $html    = '';

  if ($length >= $self->{'subslice_length'}) {
    $html .= $self->chunked_content($length, $self->{'subslice_length'}, { length => $length, name => $slice->name });
  } else {
    $html .= $self->content_sub_slice($slice,1); # Direct call if the sequence length is short enough
  }

  return $html;
}

sub content_sub_slice {
  my ($self, $slice,$fake) = @_;
  my $hub     = $self->hub;
  my $start   = $hub->param('subslice_start') || 0;
  my $end     = $hub->param('subslice_end');
  my $length  = $hub->param('length');
     $slice ||= $self->get_slice;
  my $name    = $self->get_slice_name($slice);
     $slice   = $slice->sub_Slice($start, $end) if $start && $end;

  $self->view->output(EnsEMBL::Web::TextSequence::Output::WebSubslice->new) unless $fake;

  my ($sequence, $config) = $self->initialize_new($slice, $start, $end);

  my $metatemplate = '<pre class="text_sequence%s">%s%%s</pre><p class="invisible">.</p>';
  my $template = sprintf $metatemplate, ($start == 1) || ($end && $end != $length) ? ' no-bottom-margin' : '', $start == 1 || !$start ? "&gt;$name\n" : '';
  $self->view->output->template($template);

  $self->id('');

  return $self->build_sequence_new($sequence, $config);
}

sub make_view {
  my ($self) = @_;

  return EnsEMBL::Web::TextSequence::View::BLAST->new($self->hub);
}

1;

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::JSONServer::Tools;

use strict;
use warnings;

use EnsEMBL::Web::File::Utils::URL;

use parent qw(EnsEMBL::Web::JSONServer);

sub object_type { 'Tools' }

sub call_js_panel_method {
  # TODO - get rid of this - Let frontend decide what methods to call
  my ($self, $method_name, $method_args) = @_;
  return {'panelMethod' => [ $method_name, @{$method_args || []} ]};
}

sub json_form_submit {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $ticket    = $object->ticket_class->new($object);

  $ticket->process;

  if (my $error = $ticket->error) {
    return $self->call_js_panel_method('ticketNotSubmitted', [ $error ]);
  }

  return $self->call_js_panel_method('ticketSubmitted');
}

sub json_save {
  my $self = shift;

  $self->object->save_ticket_to_account;

  return $self->call_js_panel_method('refresh', [ 1 ]);
}

sub json_delete {
  my $self = shift;

  $self->object->delete_ticket_or_job;

  return $self->call_js_panel_method('refresh', [ 1 ]);
}

sub json_refresh_tickets {
  my $self          = shift;
  my $tickets_old   = $self->hub->param('tickets');

  my ($tickets_new, $auto_refresh) = $self->object->get_tickets_data_for_sync;

  return $self->call_js_panel_method('updateTicketList', [ $tickets_old eq $tickets_new ? undef : $tickets_new, $auto_refresh ]);
}

sub json_share {
  my $self        = shift;
  my $object      = $self->object;
  my $visibility  = $object->change_ticket_visibility($self->hub->param('share') ? 'public' : 'private');

  return { 'shared' => $visibility eq 'public' ? 1 : 0 };
}

sub json_load_ticket {
  my $self = shift;

  return $self->call_js_panel_method('populateForm', [ $self->object->get_edit_jobs_data ]);
}

#Ajax request used by all 1000genomes tools to retrieve content for sample population url and return 
sub json_read_sample_file {
  my ($self) = @_;
  
  my $hub   = $self->hub;   
  my $url   = $hub->param('population_url') or return;
  my $pops  = [];
  my $args = { 'no_exception' => 1 };
  my $proxy = $hub->species_defs->ENSEMBL_WWW_PROXY;
  
  $args->{proxy}  = $proxy ? $proxy : "";  
  my $html        = EnsEMBL::Web::File::Utils::URL::read_file($url, $args); 
  
  return { 'error' => 'cannot retrieve file' } unless $html;
   
  my $sample_pop; 
  
  if ( $html ){
    foreach (split("\n",$html)){
      next if(!$_ || $_ =~ /sample/gi); #skip if empty or skip header if there is one
      my ($sam, $pop, $plat) = split(/\t/, $_);
      $sample_pop->{$pop} ||= [];
      push @{$sample_pop->{$pop}}, $sam;    
    }
  }
  #push @$pops, { caption =>'ALL', value=>'ALL', 'selected' => 'selected'}; #They might already have all in the sample file or it might not be needed. If thats not the case, uncomment
  for my $population (sort {$a cmp $b} keys %{$sample_pop}) {
    push @{$pops}, { value => $population,  caption => $population };
  }

  return { 'populations' => $pops };
}

1;

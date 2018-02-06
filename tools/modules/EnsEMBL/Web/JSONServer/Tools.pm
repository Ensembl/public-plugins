=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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
use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

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

  if (!$hub->param('species') || $hub->param('species') eq '') {
    my $sp_err = {
      'heading' => "No species selected",
      'message' => "Please select a species to run BLAST/BLAT against.",
      'stage'   => "validation"
    };
    return $self->call_js_panel_method('ticketNotSubmitted', [ $sp_err ]);
  }

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
  
  my $hub       = $self->hub;   
  my $url       = $hub->param('population_url') or return;
  my $pop_value = $hub->param('pop_value') ? 1 : 0;
  my $pops      = [];
  my $args      = { 'no_exception' => 1 };
  my $proxy     = $hub->web_proxy;
  
  $args->{proxy}  = $proxy ? $proxy : "";  
  my $html        = EnsEMBL::Web::File::Utils::URL::read_file($url, $args); 
  
  return { 'error' => 'cannot retrieve file' } unless $html;
   
  my $sample_pop; 
  
  if ( $html ){
    foreach (split("\n",$html)){
      next if(!$_ || $_ =~ /sample/gi); #skip if empty or skip header if there is one
      my ($sam, $pop, $plat) = split(/\t/, $_);
      #validation check to make sure we get valid content from the file (ex is if user uploaded utf-16 file format which has strange characters at the start)
      return { 'format_error' => "The sample population file formatting is wrong. Please check if it has the correct spacing." } if($_ !~ /^[a-z]/gi || !$pop || !$sam);
      $sample_pop->{$pop} ||= [];
      push @{$sample_pop->{$pop}}, $sam;    
    }
  }
  #push @$pops, { caption =>'ALL', value=>'ALL', 'selected' => 'selected'}; #They might already have all in the sample file or it might not be needed. If thats not the case, uncomment
  for my $population (sort {$a cmp $b} keys %{$sample_pop}) {
    my $ind_list = join(',' , @{$sample_pop->{$population}}) if($pop_value);
    push @{$pops}, { value => $ind_list ? $ind_list : $population,  caption => $population };
  }

  return { 'populations' => $pops };
}

#Ajax request used by all 1000genomes tools (data slicer) to retrieve individuals inside a vcf file
sub json_get_individuals {
  my ($self) = @_;

  my $hub     = $self->hub;   
  my $pops    = [];
  my $url     = $hub->param('file_url') or return;
  my $region  = $hub->param('region') or return;
  my ($vcf, $error);

  eval {
      $vcf = dynamic_require('Vcf')->new(file=>$url, region=>$region,  print_header=>1, silent=>1, tabix=>$SiteDefs::TABIX, tmp_dir=>$SiteDefs::ENSEMBL_TMP_TMP);  #print_header allows print sample name rather than column index
  };
  $error = "Error reading VCF file" unless ($vcf);

  if ($vcf) {
    $vcf->parse_header();
    my $x=$vcf->next_data_hash();

    for my $individual (keys %{$$x{gtypes}}) {
      push @{$pops}, { value => $individual,  name => $individual };
    }
    $error = "No data found in the uploaded VCF file within the region $region. Please choose another region or another file" unless (scalar @{$pops});
  }   
  return $error ? {'vcf_error' => $error } : { 'individuals' => $pops };  
}

1;

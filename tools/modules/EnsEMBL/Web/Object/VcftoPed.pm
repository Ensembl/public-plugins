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

package EnsEMBL::Web::Object::VcftoPed;

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use EnsEMBL::Web::DBSQL::ArchiveAdaptor;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self        = shift;
  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket   or return [];
  my $job         = shift @{ $ticket->job || [] } or return [];
  my $job_data    = $job->job_data->raw;
  
  return [ $job_data ];
}

sub species_list {
  ## Returns a list of species
  ## @return Arrayref of hashes with each hash having species specific info
  my $self = shift;

  if (!$self->{'_species_list'}) {
    my $hub = $self->hub;
    my $sd  = $hub->species_defs;

    my @species;

    for ($self->valid_species) {
      next if $_ ne "Homo_sapiens"; #restricting species list to human only(if we want it to go on www), remove this if you want full list of species

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME')
      };
    }

    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }

  return $self->{'_species_list'};
}

sub handle_download {
### Retrieves file contents and outputs direct to Apache
### request, so that the browser will download it instead
### of displaying it in the window.
### Uses Controller::Download, via url /Download/VCFTOPED/

  my ($self, $r) = @_;
  my $hub     = $self->hub;
  my $ticket  = $self->get_requested_ticket or return;
  my $job     = $ticket->job->[0] or return;   

  my $filename    = $hub->param('info') ? $job->dispatcher_data->{'output_info'} : $job->dispatcher_data->{'output_ped'}.".gz";
  #my $content     = file_get_contents(join('/', $job->job_dir, $filename), sub { s/\R/\r\n/r });

  $r->content_type('application/octet-stream');
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s', $filename);
  
  return $r->sendfile(join('/', $job->job_dir, $filename));
}

1;

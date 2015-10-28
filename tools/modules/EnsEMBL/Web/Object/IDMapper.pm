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

package EnsEMBL::Web::Object::IDMapper;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use parent qw(EnsEMBL::Web::Object::Tools);

sub get_edit_jobs_data {
  ## Abstract method implementation
  my $self        = shift;
  my $hub         = $self->hub;
  my $ticket      = $self->get_requested_ticket   or return [];
  my $job         = shift @{ $ticket->job || [] } or return [];
  my $job_data    = $job->job_data->raw;
  my $input       = delete $job_data->{'input'};

  if ($input->{'type'} eq 'text') {
    $job_data->{'text'} = file_get_contents(sprintf '%s/%s', $job->job_dir, delete $job_data->{'input_file'});
  } else {
    $input->{$_} and $job_data->{$_} = $input->{$_} for qw(url file);
  }

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

    for ($sd->tools_valid_species) {

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

1;

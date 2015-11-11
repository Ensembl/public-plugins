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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
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

sub get_stable_id_link {
  ## Gets a url for the given id and release
  ## @param Stable id
  ## @param Release number
  ## @return Hashref as accepted by hub->url or undef if no link is available
  my ($self, $stable_id, $release) = @_;

  my $hub = $self->hub;

  # we can only show link if stable id db is available
  if (!exists $self->{'_stable_id_db'}) {

    my %db = %{$hub->species_defs->multidb->{'DATABASE_STABLE_IDS'} || {}};

    $self->{'_stable_id_db'} = keys %db ? Bio::EnsEMBL::DBSQL::DBAdaptor->new(
      -species => 'multi',
      -group   => 'stable_ids',
      -host    => $db{'HOST'},
      -port    => $db{'PORT'},
      -user    => $db{'USER'},
      -pass    => $db{'PASS'},
      -dbname  => $db{'NAME'}
    ) :  undef;
  }

  return unless $self->{'_stable_id_db'};

  # Remove versioning for stable ids
  $stable_id =~ s/\.[0-9]+$//;

  my $url;
  my $retired = $hub->species_defs->ENSEMBL_VERSION != $release;
  my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id, undef, undef, undef, undef, 1);

  if ($object_type) {
    if ($object_type eq 'Gene') {
      $url = {
        'species' => $species,
        'type'    => 'Gene',
        'action'  => $retired ? 'Idhistory' : 'Summary',
        'db'      => $db_type,
        'g'       => $stable_id
      };
    } elsif ($object_type eq 'Transcript') {
      $url = {
        'species' => $species,
        'type'    => 'Transcript',
        'action'  => $retired ? 'Idhistory' : 'Summary',
        'db'      => $db_type,
        't'       => $stable_id
      };
    } elsif ($object_type eq 'Translation') {
      $url = {
        'species' => $species,
        'type'    => 'Transcript',
        'action'  => $retired ? 'Idhistory/Protein' : 'ProteinSummary',
        'db'      => $db_type,
        't'       => $stable_id
      };
    } elsif ($object_type eq 'GeneTree' && !$retired) {
      $url = {
        'species' => 'Multi',
        'type'    => 'GeneTree',
        'action'  => 'Image',
        'db'      => $db_type,
        'gt'      => $stable_id
      };
    } elsif ($object_type eq 'Family' && !$retired) {
      $url = {
        'species' => 'Multi',
        'type'    => 'Family',
        'action'  => 'Details',
        'db'      => $db_type,
        'fm'      => $stable_id
      };
    }
  }

  return $url;
}

1;

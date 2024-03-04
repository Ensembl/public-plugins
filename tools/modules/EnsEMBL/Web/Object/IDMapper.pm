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

package EnsEMBL::Web::Object::IDMapper;

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
  my $input       = delete $job_data->{'input'};

  if ($input->{'type'} eq 'text') {
    $job_data->{'text'} = file_get_contents(sprintf '%s/%s', $job->job_dir, delete $job_data->{'input_file'});
  } else {
    $input->{'type'} eq $_ and $job_data->{$_} = $input->{$_} for qw(url file);
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

    for ($self->valid_species) {

      ## Do we have data for this species?
      my $history = $sd->table_info_other($_, 'core', 'stable_id_event');

      push @species, {
        'value'       => $_,
        'caption'     => $sd->species_label($_, 1),
        'assembly'    => $sd->get_config($_, 'ASSEMBLY_NAME')
      } if $history->{'rows'};
    }

    @species = sort { $a->{'caption'} cmp $b->{'caption'} } @species;

    $self->{'_species_list'} = \@species;
  }

  return $self->{'_species_list'};
}

sub handle_download {
  ## Method reached by url ensembl.org/Download/IDMapper/
  my ($self, $r) = @_;
  my $job = $self->get_requested_job;

  my $result_file = sprintf '%s/%s', $job->job_dir, $job->dispatcher_data->{'output_file'};

  my $content = file_get_contents($result_file, sub { s/\R/\r\n/r });

  $r->headers_out->add('Content-Type'         => 'text/plain');
  $r->headers_out->add('Content-Length'       => length $content);
  $r->headers_out->add('Content-Disposition'  => sprintf 'attachment; filename=%s.idmapper.txt', $self->create_url_param);

  print $content;
}

sub get_archive_link {
  ## Gets an archive url for the given id and release
  ## @param Stable id
  ## @param Release number
  ## @return URL string (possible full URL for archives)
  my ($self, $stable_id, $release) = @_;

  # base url for the archive - returns undef if archive is not available
  my $base = $self->_get_archive_base_url($release);
  return unless defined $base;

  # get stable id link for the given id
  my $url = $self->_get_stable_id_url($stable_id);

  return $url && $base.$url;
}

sub _get_stable_id_url {
  ## @private
  my ($self, $stable_id) = @_;
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

  my ($species, $object_type, $db_type) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id, undef, undef, undef, undef, 1);

  return unless $object_type;

  $species = ucfirst($species || '');

  my $url;

  if ($object_type eq 'Gene') {
    $url = {
      'species' => $species,
      'type'    => 'Gene',
      'action'  => 'Summary',
      'db'      => $db_type,
      'g'       => $stable_id
    };
  } elsif ($object_type eq 'Transcript') {
    $url = {
      'species' => $species,
      'type'    => 'Transcript',
      'action'  => 'Summary',
      'db'      => $db_type,
      't'       => $stable_id
    };
  } elsif ($object_type eq 'Translation') {
    $url = {
      'species' => $species,
      'type'    => 'Transcript',
      'action'  => 'ProteinSummary',
      'db'      => $db_type,
      't'       => $stable_id
    };
  } elsif ($object_type eq 'GeneTree') {
    $url = {
      'species' => 'Multi',
      'type'    => 'GeneTree',
      'action'  => 'Image',
      'db'      => $db_type,
      'gt'      => $stable_id
    };
  } elsif ($object_type eq 'Family') {
    $url = {
      'species' => 'Multi',
      'type'    => 'Family',
      'action'  => 'Details',
      'db'      => $db_type,
      'fm'      => $stable_id
    };
  }

  return $url && $hub->url($url);
}

sub _get_archive_base_url {
  ## @private
  my ($self, $release) = @_;

  my $hub = $self->hub;

  return '' if $release eq $hub->species_defs->ENSEMBL_VERSION;

  my $adaptor       = $self->{'_archive_adaptor'} ||= EnsEMBL::Web::DBSQL::ArchiveAdaptor->new($hub);
  my $release_info  = $adaptor->fetch_release($release);

  return $release_info && $release_info->{'archive'} && $release_info->{'online'} eq 'Y' ?  "http://$release_info->{'archive'}.archive.ensembl.org" : undef;
}

1;

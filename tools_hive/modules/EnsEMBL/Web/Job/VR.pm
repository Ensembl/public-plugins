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

package EnsEMBL::Web::Job::VR;

### plugin to add extra parameters to VEP job before submitting it to Hive dispatcher

use strict;
use warnings;

use previous qw(prepare_to_dispatch);

sub prepare_to_dispatch {
  my $self    = shift;
  my $data    = $self->PREV::prepare_to_dispatch(@_);
  my $sd      = $self->hub->species_defs;
  my $options = $sd->ENSEMBL_VR_SCRIPT_DEFAULT_OPTIONS;

  $data->{'script_options'} = { map { defined $options->{$_} ? ( $_ => $options->{$_} ) : () } keys %$options }; # filter out the undef values
  $data->{'code_root'}      = $sd->ENSEMBL_HIVE_HOSTS_CODE_LOCATION;

  return $data;
}

1;

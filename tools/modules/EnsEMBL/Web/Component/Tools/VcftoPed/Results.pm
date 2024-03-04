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

package EnsEMBL::Web::Component::Tools::VcftoPed::Results;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::VcftoPed);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Component::Tools::NewJobButton;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $job     = $object->get_requested_job({'with_all_results' => 1});
  my $current = $hub->species_defs->ENSEMBL_VERSION;
   
  my $info_download_url = $object->download_url.";info=1";
  my $ped_download_url  = $object->download_url.";ped=1";

  return '' unless $job;
  
  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );

  my $download_button = qq{<div class="component-tools tool_buttons"><a class="export" href="$info_download_url">Download Marker Information File</a><a class="export left-margin" href="$ped_download_url">Download Linkage Pedigree File</a><div class="left-margin">$new_job_button</div></div>};
  
  return (scalar @{$job->result}) ? qq{<p>Your linkage pedigree and marker information files have been generated. Click on the files below to download them.</p><p>$download_button</p>} : $self->_warning('No results', 'No results obtained.');
}

1;

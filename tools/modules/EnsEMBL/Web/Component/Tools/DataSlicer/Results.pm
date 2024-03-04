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

package EnsEMBL::Web::Component::Tools::DataSlicer::Results;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools::DataSlicer);

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Component::Tools::NewJobButton;

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $current   = $hub->species_defs->ENSEMBL_VERSION;
  my $filename  = $job->dispatcher_data->{'output_file'};
  
  my $download_url      = $object->download_url;
  my $bai_download_url  = $object->download_url.";bai=1";

  return '' unless $job;
  
  my ($text, $download_button);

  my $button_url = $hub->url({'function' => undef, 'expand_form' => 'true'});
  my $new_job_button = EnsEMBL::Web::Component::Tools::NewJobButton->create_button( $button_url );
  
  if($job->dispatcher_data->{'file_format'} eq 'bam') {
    $text            = -s join('/', $job->job_dir, $filename.".bai") ? "Your BAM and index (.bai) files have been generated." : "Your BAM file has been generated.";  
    $download_button = qq{<div class="component-tools tool_buttons"><a class="export right-margin" href="$download_url">Download results file (.bam)</a>};
    $download_button .= qq{<a class="export right-margin " href="$bai_download_url">Download index file (.bai)</a>} if(-s join('/', $job->job_dir, $filename.".bai"));
    $download_button .= $new_job_button . "</div>";
    $filename        = "bam_preview.txt";
  } else {
    $text            = "Your VCF file has been generated.";
    $download_button = qq{<div class="component-tools tool_buttons"><a class="export right-margin" href="$download_url">Download results file</a>$new_job_button</div>};
    $filename        = "preview.vcf";
  }
  
  my $content   = file_get_contents(join('/', $job->job_dir, $filename), sub { s/\R/\r\n/r });
  my $preview   = "<h3>Preview</h3>$content";

  if( scalar(split('\n',$content)) > 1){
    
    return qq{<p>$text Click on the button below to download the file.</p><p>$download_button</p><p><h3>Results preview</h3><textarea cols="80" rows="10" wrap="off" readonly="yes">$content</textarea></p>};
  
  }

  return $self->_warning('No results', 'No results obtained.') . '<div class="component-tools tool_buttons bottom-margin">' . $new_job_button . '</div>';


}

1;

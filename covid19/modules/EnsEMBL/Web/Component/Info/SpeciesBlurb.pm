=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Info::SpeciesBlurb;

use strict;

sub content {
  ## Simple template that we can populate differently in plugins
  my $self              = shift;

  my $html;

  if ($self->hub->species eq 'Sars_cov_2') {

    $html = sprintf('
<div class="column-wrapper">  
  <div class="column-one">
    %s
  </div>
</div>', $self->page_header);

    $html .= sprintf('
<div class="column-wrapper">  
  <div class="column-two">
    %s
  </div>
  <div class="column-two">
    %s
  </div>
</div>',
    $self->column_left, $self->column_right);

  }
  else {

    $html = sprintf('
<div class="column-wrapper">  
  <div class="column-one">
    %s
    %s
  </div>
</div>', $self->page_header, $self->column_right);
  }
}


sub _wikipedia_link {

  return '';
}

1;

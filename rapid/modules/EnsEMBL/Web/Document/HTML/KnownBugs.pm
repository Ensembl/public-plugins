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

package EnsEMBL::Web::Document::HTML::KnownBugs;

### This module retrieves the "known bugs" HTML fragment from
### the server's tmp directory 

use strict;

use EnsEMBL::Web::File::Utils::IO qw(file_exists read_file);

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self  = shift;
  
  my $html = qq(<p>
Ensembl strives to deliver the highest quality resources for the research community. 
However there are times that we discover errors in our released databases either due to 
our own mistakes, or errors and inconsistencies in our input data sources. We list these bugs here 
as they are discovered. In every case, we correct these bugs as soon as they are discovered and 
normally provide these corrections in the next Ensembl Rapid release.
</p>);

  my $file = $self->hub->species_defs->ENSEMBL_TMP_DIR.'/known_bugs.inc';
  my $args = {'no_exception' => 1};
  my $content;

  if (file_exists($file, $args)) {
    $content = read_file($file, $args);
  }

  $html .= $content ? $content : '<p>There are no known bugs at this time.</p>';

  return $html;
}

1;

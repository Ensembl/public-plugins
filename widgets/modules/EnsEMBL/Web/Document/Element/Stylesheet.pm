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

## DESCRIPTION: Adding new stylesheet from external link for gene expression atlas

package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Document::Element);

use previous qw(content);


sub content {
  my $self = shift;
  
  my $main_css = $self->PREV::content(@_);

  return $main_css unless $self->hub->action eq 'ExpressionAtlas'; #adding stylesheet only for gene expression atlas view

  $main_css .=  qq{
    <link rel="stylesheet" type="text/css" media="all" href="http://www.ebi.ac.uk/gxa/resources/css/atlas.css" />
    <link rel="stylesheet" type="text/css" media="all" href="http://www.ebi.ac.uk/gxa/resources/js/jquery-ui-1.10.2.custom/css/ui-lightness/jquery-ui-1.10.2.custom.min.css"/>

    <link rel="stylesheet" type="text/css" media="all" href="http://www.ebi.ac.uk/gxa/resources/css/table-grid.css" />
    <link rel="stylesheet" type="text/css" media="all" href="http://www.ebi.ac.uk/gxa/resources/css/heatmap-and-anatomogram.css" />
  };

  return  $main_css;
  
}


1;

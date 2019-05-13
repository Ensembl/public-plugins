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

## DESCRIPTION: Adding new stylesheet from external link for gene expression atlas

package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Document::Element);

use previous qw(content);


sub content {
  my $self = shift;
  
  my $main_css      = $self->PREV::content(@_);
  my $static_server = $self->static_server ? $self->static_server : '';
  
  if ($self->hub->action && $self->hub->action eq 'ExpressionAtlas' && $self->hub->gxa_status) {
    #adding stylesheet only for gene expression atlas view
    $main_css .=  qq{
      <link rel="stylesheet" type="text/css" href="$static_server/widgets/90_GXA.css"> 
      <link rel="stylesheet" type="text/css" href="$SiteDefs::GXA_EBI_URL/css/alt-customized-bootstrap-3.3.5.css">
      <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/babel-polyfill.min.js"></script>
      <script language="JavaScript" type="text/javascript" src="$SiteDefs::GXA_EBI_URL/js/lib/fetch-polyfill.min.js"></script>
    };
  }
  elsif ($self->hub->action && $self->hub->action eq 'Pathway' && $self->hub->pathway_status) {
    $main_css .=  qq{
      <link rel="stylesheet" type="text/css" href="$static_server/widgets/95_Pathway.css"> 
    };
  }
  elsif ($self->hub->action && ($self->hub->action eq 'PDB' || ($self->hub->action eq 'VEP' && $self->hub->function && $self->hub->function eq 'PDB'))) {
    $main_css .=  qq{
      <link rel="stylesheet" type="text/css" href="$SiteDefs::PDBE_EBI_URL/v1.0/css/pdb.component.library.min-1.0.0.css" />
    };
  }

  return  $main_css;  
}


1;

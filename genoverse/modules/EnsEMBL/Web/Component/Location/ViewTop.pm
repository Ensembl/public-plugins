=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

# $Id$

package EnsEMBL::Web::Component::Location::ViewTop;

use strict;

use previous qw(content);

use base qw(EnsEMBL::Web::Component::Location::Genoverse);

sub new_image {
  # The plugin system causes confusion as to what is inherited. Make sure the right function is called
  return EnsEMBL::Web::Component::Location::Genoverse::new_image(@_);
}

sub content      { return $_[0]->content_test;  }
sub content_main { return $_[0]->PREV::content; }

1;

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

package EnsEMBL::ORM::Component::DbFrontend::Problem;

use strict;
use warnings;

use parent qw(EnsEMBL::ORM::Component::DbFrontend);

sub content_tree {
  my $self  = shift;
  my $error = $self->hub->param('error');
     $error = $error ? "Error: $error" : 'Please try again.';

  return $self->dom->create_element('div', {
    'class'      => [$self->object->content_css, $self->_JS_CLASS_RESPONSE_ELEMENT],
    'inner_HTML' => qq(<p class="dbf-error">Sorry, an error occurred while updating information to the database.<br />$error</p>)
  });
}

1;

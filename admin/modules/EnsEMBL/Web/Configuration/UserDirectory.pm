=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::UserDirectory;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Configuration);

sub caption       { 'User Directory'; }
sub short_caption { 'User Directory'; }

sub set_default_action {
  shift->{'_data'}{'default'} = 'View';
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element($_) for qw(tabs summary);
}

sub populate_tree {
  my $self = shift;

  $self->create_node( 'View', "View all",
    [qw(
      session_info    EnsEMBL::Admin::Component::UserDirectory
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
}

1;
                  

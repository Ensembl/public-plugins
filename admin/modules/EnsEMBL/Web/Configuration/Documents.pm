=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Configuration::Documents;

use strict;

use parent qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'View';
}

sub populate_tree {
  my $self  = shift;
  my $hub   = $self->hub;
  my $docs  = $self->object ? $self->object->available_documents : [];

  $self->create_node("View", 'View',
      [ 'view' => 'EnsEMBL::Admin::Component::Documents::View' ],
      { 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
  );

  while (my ($func, $doc) = splice @$docs, 0, 2) {

    my $menu  = $self->create_submenu($doc->{'title'}, $doc->{'title'});

    $menu->append($self->create_node("View/$func", 'View',
      [ 'view' => 'EnsEMBL::Admin::Component::Documents::View' ],
      { 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));

    $menu->append($self->create_node("Error/$func", 'Error',
      [ 'error' => 'EnsEMBL::Admin::Component::Documents::View' ], # Intentionally kept same as View Component
      { 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
    ));

# TODO - Not yet implemented using git
#     unless ($doc->{'readonly'}) {
#       $menu->append($self->create_node("Edit/$func", 'Edit',
#         [ 'view' => 'EnsEMBL::Admin::Component::Documents::Edit' ],
#         { 'availability' => 1, 'filters' => ['WebAdmin'] }
#       ));
# 
#       $menu->append($self->create_node("Preview/$func", 'Preview',
#         [ 'view' => 'EnsEMBL::Admin::Component::Documents::Preview' ],
#         { 'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
#       ));
#     }

    $menu->append($self->create_node("Update/$func", 'Update', [],
      { 'command' => 'EnsEMBL::Admin::Command::Documents::Update', 'availability' => 1, 'filters' => ['WebAdmin'] }
    ));

#     $self->create_node("Save/$func", 'Save', [],
#       { 'command' => 'EnsEMBL::Admin::Command::Documents::Save',   'availability' => 1, 'filters' => ['WebAdmin'], 'no_menu_entry' => 1 }
#     );
  }
}

1;

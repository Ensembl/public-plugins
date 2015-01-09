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

package EnsEMBL::Web::Configuration::News;

### NAME: EnsEMBL::Web::Configuration:News
### Default node and general settings for the News pages

### STATUS: Stable

### DESCRIPTION:
### A standard Configuration module. Note that by default, there are
### no CRUD nodes - these are added in the admin plugin, since most
### users won't need this functionality or wish it to be exposed on
### the web. There is however a custom display node so that non-admin
### users can view site news

use strict;

use parent qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Summary';
}

sub short_caption {}
sub caption {}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element('tabs');
  $page->remove_body_element('tool_buttons');
  $page->remove_body_element('summary');
}

sub populate_tree {
  my $self = shift;

  $self->create_node( 'Summary', "What's New in Ensembl",
    [qw(summary   EnsEMBL::Admin::Component::News::Summary)],
    {'availability' => 1},
  );
}

1;

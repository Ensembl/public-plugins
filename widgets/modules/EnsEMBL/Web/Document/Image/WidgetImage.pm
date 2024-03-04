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

package EnsEMBL::Web::Document::Image::WidgetImage;


use JSON qw(to_json);

use parent qw(EnsEMBL::Web::Document::Image);

sub new {
  my ($class, $hub, $component) = @_;
  my $args = {
    hub           => $hub,
    component     => $component,
    component_id  => ref $component ? $component->id : $component, # TMP - change it to $component->id when $component is a Component instance
    export        => 'iexport no_text',
  };
  $args->{'toolbars'}{'top'}  = 1;

  return bless $args, $class;
}


sub render {
  my $self         = shift;
  my $tree         = shift;
  
  my ($top_toolbar, $bottom_toolbar) = $self->render_toolbar();
  
  my $html = sprintf('
    <div class="info"></div>
    <input type="hidden" class="panel_type" value="Widget" />
    <div id="widget" class="image_container ui-resizable js_tree">
      %s
      %s
    </div>',    
    $top_toolbar,
    $tree,
  );
  return $html;
}

sub render_toolbar {
  my $self = shift;

  ## Add icons specific to our standard dynamic images
  my $hub         = $self->hub;
  my $component   = $self->component;
  my $component_name = ref($component) ? $component->id : $component;  

  my $icons  = [];
  my $extra_html;

  push @$icons, $self->add_share_icon;     
 
  push @$icons, $self->add_image_export_icon;
  push @$icons, $self->add_export_icon;
  
  return $self->_render_toolbars($icons, $extra_html);
}



1;

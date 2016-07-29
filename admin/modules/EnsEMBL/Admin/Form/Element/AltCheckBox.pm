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

package EnsEMBL::Admin::Form::Element::AltCheckBox;

### Alternative checkbox rendering, for healthcheck config form

use strict;
use parent qw( EnsEMBL::Web::Form::Element );

use CGI qw(escapeHTML);

sub new {
  my $class = shift;
  my %params = @_;
  my $self = $class->SUPER::new( %params );
  $self->checked = $params{'checked'};
  if ($params{'long_label'}) {
    $self->add_class('checkbox-long');
  }
  return $self;
}

sub checked  :lvalue { $_[0]->{'checked'};  }
sub disabled :lvalue { $_[0]->{'disabled'}; }

sub render {
  my $self = shift;
  return sprintf(
    qq(
  <tr>
    <td%s>
      <label>%s</label>
    </th>
    <td%s>
      <input type="checkbox" name="%s" id="%s" value="%s" class="input-checkbox"%s%s/>%s
    </td>
  </tr>),
    $self->class_attrib,
    $self->{'raw'} ? $self->label : CGI::escapeHTML( $self->label ), 
    $self->class_attrib,
    CGI::escapeHTML( $self->name ), 
    CGI::escapeHTML( $self->id ),
    $self->value || 'yes',
    $self->checked ? ' checked="checked" ' : '',
    $self->disabled ? ' disabled="disabled" ' : '',
    $self->notes,
  );
}
                                                                                
sub validate { return 1; }
1;

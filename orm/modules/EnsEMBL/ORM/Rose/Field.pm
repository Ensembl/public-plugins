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

package EnsEMBL::ORM::Rose::Field;

### NAME: EnsEMBL::ORM::Rose::Field;
### Each object of this class acts as a data structure for displaying individual Field(E::W::Form::Field) in Form

### STATUS: Under development

### DESCRIPTION: A very simple object to simplify the work for displaying forms in the DbFrontend components

use strict;

use Rose::DateTime::Util qw(format_date parse_date);

sub name              { return shift->{'_name'};    }
sub label             { return shift->{'_label'};   }
sub field_type        { return shift->{'_f_type'};  }
sub value             { return shift->{'_value'};   }
sub caption           { return shift->{'_caption'}; }
sub lookup            { return shift->{'_lookup'};  }
sub selected          { return shift->{'_values'};  }
sub multiple          { return shift->{'_multi'};   }
sub value_type        { return shift->{'_v_type'};  }
sub is_null           { return shift->{'_is_null'}; }
sub extras            { return shift->{'_extras'};  }
sub is_datastructure  { return shift->{'_is_ds'};   }
sub is_column         { return shift->{'_is_col'};  }

sub new {
  my ($class, $params) = @_;
  
  (my $label = $params->{'name'}) =~ s/_/ /g;
  
  my $caption = ref $params->{'value'} eq 'ARRAY' ? '' : $params->{'value'};
  $caption    = $caption->get_title if UNIVERSAL::can($caption, 'get_title');
  $caption    = format_date(parse_date($caption), "%b %e, %Y at %H:%M") if $params->{'value_type'} eq 'datetime';
  
  $params->{'value'} = $params->{'value'}->get_primary_key_value if UNIVERSAL::can($params->{'value'}, 'get_primary_key_value');
  $params->{'value'} = '' unless defined $params->{'value'};

  return bless {
    '_name'    => delete $params->{'name'},
    '_label'   => delete $params->{'label'} || ucfirst $label,
    '_value'   => delete $params->{'value'},
    '_lookup'  => delete $params->{'lookup'} || {},
    '_is_ds'   => delete $params->{'is_datastructure'} || 0,
    '_v_type'  => delete $params->{'value_type'},
    '_f_type'  => delete $params->{'type'} || 'noedit',
    '_values'  => delete $params->{'selected'} || {},
    '_multi'   => delete $params->{'multiple'} || 0,
    '_is_null' => delete $params->{'is_null'}  || 0,
    '_is_col'  => delete $params->{'is_column'}  || 0,
    '_caption' => $caption,
    '_extras'  => $params
  }, $class;
}

1;
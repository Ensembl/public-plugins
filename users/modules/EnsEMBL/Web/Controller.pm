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

package EnsEMBL::Web::Controller;

use strict;

## TODO - move to webcode and allow histpry to be saved to sessions

## TODO - this needs improvement
## 1. History is saved looking into the referer - in this way we can lose last history item if user navigates away from ensembl
## 2. if-else statements on $referer_type should be avoided here, and those rules need to be moved to respecitve Factory/Object/Configuration.

# sub update_user_history {
#   ## Updates user history (ie. adds a history record for the logged in user)
#   ## Call this method only if user is logged in
#   my $self            = shift;
#   my $hub             = $self->hub;
#   my $r_user          = $hub->user->rose_object;
#   my $referer         = $hub->referer;
#   my $referer_type    = $referer->{'ENSEMBL_TYPE'};
#   my $referer_species = $referer->{'ENSEMBL_SPECIES'};
#   my $param           = $referer_type ? $hub->object_types->{$referer_type} : undef;
# 
#   return unless $referer_type && $param;
# 
#   my @type_history    = grep $_->object eq $referer_type, @{$r_user->histories};
#   my $value           = shift || $referer->{'params'}->{$param}->[0] or return;
#   my $name            = $self->species_defs->get_config($referer_species, 'SPECIES_COMMON_NAME');
# 
#   if ($referer_type =~ /^(Gene|Transcript)$/) {
#     my $db           = $referer->{'params'}->{'db'}->[0] || 'core';
#        $db           = 'otherfeatures' if $db eq 'est';
#     my $func         = "get_${referer_type}Adaptor";
#     my $feature      = $hub->get_adaptor($func, $db, $referer_species)->fetch_by_stable_id($value);
#     my $display_xref = $feature ? $feature->display_xref : undef;
# 
#     $name .= ': ' . ($display_xref ? $display_xref->display_id : $value);
#   } elsif ($referer_type eq 'Phenotype') {
#     $name .= ': ' . $hub->get_adaptor('get_PhenotypeAdaptor', 'variation', $referer_species)->fetch_by_dbID($value)->description;
#   } elsif ($referer_type eq 'Experiment') {
#     $value = $value eq 'all' ? 'All' : join(', ', grep !/(cell_type|evidence_type|project|name)/, split chop $value, $value) unless $value =~ s/^name-//;     
#     $name .= ": $value";
#   } else {
#     $name .= $name ? ": $value" : $value;
#   }
# 
#   my $name_check = grep { $_->name eq $name } @type_history;
# 
#   if ($value && !$name_check && !($referer_type eq $self->type && $hub->param($param) eq $value)) {
#     $r_user->create_record('history', {
#       'name'    =>  $name,
#       'species' =>  $referer_species,
#       'object'  =>  $referer_type,
#       'param'   =>  $param,
#       'value'   =>  $value,
#       'url'     =>  $referer->{'absolute_url'}
#     })->save('user' => $r_user);
# 
#     ## Limit to 5 entries per object type
#     shift(@type_history)->delete while scalar @type_history >= 5; 
#   }
# }

1;

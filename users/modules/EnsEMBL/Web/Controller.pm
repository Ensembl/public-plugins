package EnsEMBL::Web::Controller;

use strict;

sub update_user_history {
  my $self            = shift;
  my $hub             = $self->hub;
  my $user            = $hub->user;
  my $referer         = $hub->referer;
  my $referer_type    = $referer->{'ENSEMBL_TYPE'};
  my $referer_species = $referer->{'ENSEMBL_SPECIES'};
  my $param           = $hub->object_types->{$referer_type};
  
  if ($referer_type && $param) {
    my @type_history = grep $_->object eq $referer_type, @{$user->histories};
    my $value        = shift || $referer->{'params'}->{$param}->[0];
    my $name         = $self->species_defs->get_config($referer_species, 'SPECIES_COMMON_NAME');
    
    if ($referer_type =~ /^(Gene|Transcript)$/) {
      my $db           = $referer->{'params'}->{'db'}->[0] || 'core';
         $db           = 'otherfeatures' if $db eq 'est';
      my $func         = "get_${referer_type}Adaptor";
      my $feature      = $hub->get_adaptor($func, $db, $referer_species)->fetch_by_stable_id($value);
      my $display_xref = $feature ? $feature->display_xref : undef;
      
      $name .= ': ' . ($display_xref ? $display_xref->display_id : $value);
    } elsif ($referer_type eq 'Phenotype') {
      $name .= ': ' . $hub->get_adaptor('get_VariationAnnotationAdaptor', 'variation')->fetch_phenotype_description_by_id($value);
    } elsif ($referer_type eq 'Experiment') {
      $value = $value eq 'all' ? 'All' : join(', ', grep !/(cell_type|evidence_type|project|name)/, split chop $value, $value) unless $value =~ s/^name-//;     
      $name .= ": $value";
    } else {
      $name .= $name ? ": $value" : $value;
    }
    
    my $name_check = grep { $_->name eq $name } @type_history;
    
    if ($value && !$name_check && !($referer_type eq $self->type && $hub->param($param) eq $value)) {
      $user->create_record('history', {
        'name'    =>  $name,
        'species' =>  $referer_species,
        'object'  =>  $referer_type,
        'param'   =>  $param,
        'value'   =>  $value,
        'url'     =>  $referer->{'absolute_url'}
      })->save('user' => $user);

      ## Limit to 5 entries per object type
      shift(@type_history)->delete while scalar @type_history >= 5; 
    }
  }
}

1;

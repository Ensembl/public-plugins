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

package EnsEMBL::Web::Component::Transcript::Haplotypes_new;

use strict;
use warnings;
no warnings 'uninitialized';

use HTML::Entities qw(encode_entities);
use JSON;

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $object = $self->object;
  
  my $html = '';
  
  # tell JS what panel type this is
  $html .= '<input type="hidden" class="panel_type" value="TranscriptHaplotypes_new" />';

  my $c = $self->get_haplotypes;
  
  my $table = $self->new_table(
    [], [], {
      data_table => 1,
      download_table => 1,
      sorting => [ 'freq desc' ],
      # data_table_config => {iDisplayLength => 10}, 
    }
  );
  
  my $total_counts = $c->total_population_counts();
  
  my $pop_objs = $c->get_all_Populations();
  my $pop_struct = $self->population_structure($pop_objs);
  
  my %pop_descs = map {$_->name => $_->description} @$pop_objs;
  
  my @pop_cols =
    map {{
      key => $self->short_population_name($_),
      title => $self->short_population_name($_),
      sort => 'numeric',
      help => sprintf('Frequency in %s: %s population (count)', $_, $pop_descs{$_})
    }}
    sort keys %$pop_struct;

  $table->add_columns(
    { key => 'protein', title => 'Protein haplotype', sort => 'none',    help => 'Haplotype names represent a comma-separated list of differences to the reference sequence'},
    { key => 'freq',    title => 'Frequency (count)', sort => 'numeric', help => 'Combined frequency across all samples and observed count in parentheses'},
    @pop_cols,
    { key => 'extra',   title => '',                  sort => 'none' }
  );
  
  my @rows;
  my $count = 0;
  
  foreach my $ph(@{$c->get_all_ProteinHaplotypes}) {    
    $table->add_row($self->render_protein_haplotype_row($ph));
  }
  
  $html .= $table->render;

  # send through JSON version of the container
  my $json = JSON->new();

  $html .= sprintf(
    '<input class="js_param" type="hidden" name="haplotype_data" value="%s" />',
    encode_entities($json->allow_blessed->convert_blessed->encode($c))
  );

  # and send population structure
  $html .= sprintf(
    '<input class="js_param" type="hidden" name="population_structure" value="%s" />',
    encode_entities($self->jsonify($pop_struct))
  );

  # and population descriptions
  $html .= sprintf(
    '<input class="js_param" type="hidden" name="population_descriptions" value="%s" />',
    encode_entities($self->jsonify({map {$_->name => $_->description} @$pop_objs}))
  );

  # add element for displaying details
  $html .= '<div class="details-view" id="details-view"><a name="details-view"/>&nbsp;</div>';

  return $html;
}

sub get_haplotypes {
  my $self = shift;
  
  my $tr = $self->object->Obj;
  
  my $variation_db = $tr->adaptor->db->get_db_adaptor('variation');
  
  # find VCF config
  my $c = $self->object->species_defs->multi_val('ENSEMBL_VCF_COLLECTIONS');

  if($c) {
   # set config file via ENV variable
   $ENV{ENSEMBL_VARIATION_VCF_CONFIG_FILE} = $c->{'CONFIG'};
   $variation_db->use_vcf($c->{'ENABLED'}) if $variation_db->can('use_vcf');
  }
  
  my $thca = $variation_db->get_TranscriptHaplotypeAdaptor();

  return $thca->get_TranscriptHaplotypeContainer_by_Transcript($tr);
}

sub short_population_name {
  my $self = shift;
  my $name = shift;
  
  my $short = $name;
  $short =~ s/1000GENOMES:phase_3://i;
  
  return $short;
}

sub population_structure {
  my $self = shift;
  my $pop_objs = shift;
  
  if(!exists($self->{_population_structure})) {
    my %pop_struct;
    foreach my $pop(@$pop_objs) {
      next if $pop->name =~ /:ALL$/;
      my $subs = $pop->get_all_sub_Populations();
      next unless $subs && scalar @$subs;
      @{$pop_struct{$pop->name}} = map {$_->name} @$subs;
    }
    
    $self->{_population_structure} = \%pop_struct;
  }
  
  return $self->{_population_structure};
}

sub population_objects {
  my $self = shift;
  my $total_counts = shift;
  
  if(!exists($self->{_population_objects})) {
    # generate population structure
    my $pop_adaptor = $self->object->Obj->adaptor->db->get_db_adaptor('variation')->get_PopulationAdaptor;
    my @pop_objs = grep {defined($_)} map {$pop_adaptor->fetch_by_name($_)} keys %$total_counts;
    
    $self->{_population_objects} = \@pop_objs;
  }
  
  return $self->{_population_objects};
}

sub render_protein_haplotype_row {
  my $self = shift;
  my $ph = shift;
  
  my $pop_objs = $self->population_objects();
  my $pop_struct = $self->population_structure;
  my %pop_descs = map {$_->name => $_->description} @$pop_objs;
  
  # create base row
  my $row = {
    protein => $self->render_protein_haplotype_name($ph),
    freq    => sprintf("%.3g (%i)", $ph->frequency, $ph->count),
  };
  
  # add per-population frequencies
  my $pop_freqs = $ph->get_all_population_frequencies;
  my $pop_counts = $ph->get_all_population_counts;
  
  foreach my $pop(keys %$pop_counts) {
    my $short_pop = $self->short_population_name($pop);
    
    $row->{$short_pop} = sprintf("%.3g (%i)", $pop_freqs->{$pop}, $pop_counts->{$pop});
  }
  
  $row->{extra} = sprintf(
    '<a href="#details-view" class="details-link" rel="%s" title="Show full details of this haplotype">Details</a>',
    $ph->_hex
  );
  
  return $row;
}

sub render_protein_haplotype_name {
  my $self = shift;
  my $ph = shift;
  
  my $name = $ph->name;
  $name =~ s/^.+?://;

  # introduce line-breaking zero-width spaces
  $name =~ s/\,/\,\&\#8203\;/g;

  return $name;
}

1;

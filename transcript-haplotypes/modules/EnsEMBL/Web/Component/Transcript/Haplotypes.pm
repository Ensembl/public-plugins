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

package EnsEMBL::Web::Component::Transcript::Haplotypes;

use strict;
use warnings;
no warnings 'uninitialized';

use Time::HiRes qw(tv_interval gettimeofday);

use Bio::EnsEMBL::Variation::TranscriptHaplotypeContainer;

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
  $html .= '<input type="hidden" class="panel_type" value="TranscriptHaplotypes" />';

  my $t0 = [gettimeofday];
  
  my $c = $self->get_haplotypes;
  
  print STDERR "HAPLOTYPES ".tv_interval($t0, [gettimeofday])."\n";
  
  my $table = $self->new_table(
    [], [], {
      data_table => 1,
      download_table => 1,
      sorting => [ 'freq desc' ],
      data_table_config => {iDisplayLength => 10}, 
    }
  );
  
  my $total_counts = $c->total_population_counts();
  
  my $pop_objs = $self->population_objects($total_counts);
  my $pop_struct = $self->population_structure;
  
  my %pop_descs = map {$_->name => $_->description} @$pop_objs;
  
  my @pop_cols =
    map {{
      key => $self->short_population_name($_),
      title => $self->short_population_name($_),
      sort => 'numeric',
      help => sprintf('<b>%s: </b>%s', $_, $pop_descs{$_})
    }}
    sort keys %$pop_struct;

  $table->add_columns(
    { key => 'protein', title => 'Protein haplotype', sort => 'none',    help => 'Haplotype names represent a comma-separated list of differences to the reference sequence'},
    { key => 'freq',    title => 'Frequency',         sort => 'numeric', help => 'Combined frequency across all samples'},
    { key => 'cds',     title => 'CDS haplotype(s)',  sort => 'none',    help => 'Haplotype names represent a comma-separated list of differences to the reference sequence'},
    # { key => 'count',       title => 'Count',             sort => 'numeric' },
    @pop_cols,
    { key => 'extra',   title => '',                  sort => 'none' }
  );
  
  my @rows;
  
  foreach my $ph(@{$c->get_all_ProteinHaplotypes}) {    
    $table->add_row($self->render_protein_haplotype_row($ph));
  }
  
  print STDERR "TOTAL ".tv_interval($t0, [gettimeofday])."\n";
  
  $html .= $table->render;

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
  
  my $vca = $variation_db->get_VCFCollectionAdaptor();
  
  # my @gts = map {@{$_->get_all_IndividualGenotypeFeatures_by_Slice($tr->feature_Slice, undef, 1)}} @{$vca->fetch_all};
  
  my @gts;

  my $t0 = [gettimeofday];

  # we don't want variants in introns
  foreach my $exon(@{$tr->get_all_Exons}) {
    push @gts, map {@{$_->get_all_SampleGenotypeFeatures_by_Slice($exon->feature_Slice, undef, 1)}} @{$vca->fetch_all};
  }
  
  print STDERR "GENOTYPES ".tv_interval($t0, [gettimeofday])."\n";
  
  print STDERR "Fetched ".(scalar @gts)." GTs\n";
  
  return Bio::EnsEMBL::Variation::TranscriptHaplotypeContainer->new(
    -transcript => $tr,
    -genotypes  => \@gts,
    -samples    => [map {@{$_->get_all_Samples}} @{$vca->fetch_all}],
    -db         => $variation_db
  );
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
  
  if(!exists($self->{_population_structure})) {
    my $pop_objs = $self->population_objects;
  
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
    count   => $ph->count,
    cds     => join('<br/>',
      map {$self->render_cds_haplotype_name($_).' ('.$_->count.')'}
      sort {$b->count <=> $a->count}
      @{$ph->get_all_CDSHaplotypes}
    ),
  };
  
  # add per-population frequencies
  my $pop_freqs = $ph->get_all_population_frequencies;
  my $pop_counts = $ph->get_all_population_counts;
  
  foreach my $pop(keys %$pop_counts) {
    my $short_pop = $self->short_population_name($pop);
    
    $row->{$short_pop} = sprintf("%.3g (%i)", $pop_freqs->{$pop}, $pop_counts->{$pop});
    
    # add sub-population frequencies
    my $sub_html = '';
    
    foreach my $sub(sort @{$pop_struct->{$pop} || []}) {
      $sub_html ||= '<table class="ss" style="width:auto; margin-top:0.5em;">';
      
      $sub_html .= sprintf(
        '<tr><td><span class="ht _ht" title="<b>%s: </b>%s">%s</span></td><td>%.3g (%i)</tr>',
        $sub,
        $pop_descs{$sub},
        $self->short_population_name($sub),
        $pop_freqs->{$sub} || '0',
        $pop_counts->{$sub} || '0'
      );
    }
    
    if($sub_html) {
      
      # close table
      $sub_html .= '</table>';
      
      # create a cell_id from the population and hex
      my $cell_id = $ph->_hex; #$short_pop.'_'.$ph->_hex;
    
      $row->{$short_pop} .= sprintf(
        '<div class="%s"><div class="toggleable" style="display:none">%s</div></div>',
        $cell_id, $sub_html
      );
    }
  }
  
  $row->{extra} = sprintf(
    '<a class="toggle closed _slide_toggle _ht" href="#" rel="%s" title="Show sub-population frequencies">Expand</a>',
    $ph->_hex
  );
  
  return $row;
}

sub render_protein_haplotype_name {
  my $self = shift;
  my $ph = shift;
  
  my $name = $ph->name;
  $name =~ s/^.+?://;
  
  my $ref_protein_length = length($ph->container->transcript->{protein});
  
  foreach my $diff(@{$ph->get_all_diffs()}) {
    my $sift_pred   = $diff->{sift_prediction};
    my $poly_pred   = $diff->{polyphen_prediction};
    my $diff_string = $diff->{diff};
    
    my ($desc, $colour, $tcolour) = ('', 'none', 'black');
    
    # STOP gained
    if($diff_string =~ /\*$/) {
      
      # get truncated length relative to ref
      # remember both ref and this pos are 1 longer than the actual sequence will be
      if($diff_string =~ m/^(\d+)/) {
        my $pos = $1;
        $desc = sprintf(
          '<b>%s: </b>stop_gained<br/><b>Truncated length: </b>%.1f%% (%i / %i aa)',
          $diff_string,
          100 * (($pos - 1) / ($ref_protein_length - 1)),
          $pos - 1,
          $ref_protein_length - 1
        );
        
        $colour = 'red';
        $tcolour = 'white';
      }
    }
    
    
    # SIFT or PolyPhen
    elsif($sift_pred || $poly_pred) {
    # elsif(($sift_pred && $sift_pred eq 'deleterious') || ($poly_pred && $poly_pred eq 'probably_damaging')) {
      $desc =
        '<b>'.$diff_string.': </b>missense_variant<br/>'.
        '<b>SIFT: </b>'.($sift_pred ? sprintf('%s (%.3f)', $sift_pred, $diff->{sift_score}) : 'no prediction').'<br/>'.
        '<b>PolyPhen: </b>'.($poly_pred ? sprintf('%s (%.3f)', $poly_pred, $diff->{polyphen_score}) : 'no prediction');
        
      if(($sift_pred && $sift_pred eq 'deleterious') || ($poly_pred && $poly_pred eq 'probably damaging')) {
        $colour = 'yellow';
      }
      
      elsif($poly_pred && $poly_pred eq 'possibly damaging') {
        $colour = 'blue';
        $tcolour = 'white';
      }
      
      else {
        $colour = 'grey';
        $tcolour = 'white';
      }
    }
    
    $name =~ s/($diff_string\*?)/<div style="background-color:$colour;color:$tcolour;display:inline-table" class="_ht score" title="$desc">$1<\/div>/ if $desc; 
  }
  
  return $name;
}

sub render_cds_haplotype_name {
  my $self = shift;
  my $ch = shift;
  
  my $name = $ch->name;
  $name =~ s/^.+?://;
  
  foreach my $diff(@{$ch->get_all_diffs()}) {
    if(my $vf = $diff->{variation_feature}) {
      my $diff_string = $diff->{diff};
      
      my $var = $vf->variation_name;
      my $url = $self->hub->url({
        type    => 'ZMenu',
        action  => 'Variation',
        v       => $var
      });

      my $desc = sprintf('<a class="zmenu" href="%s">%s</a>', $url, $diff_string);;
      
      $name =~ s/($diff_string)/$desc/; 
    }
  }
  
  return $name;
}

1;

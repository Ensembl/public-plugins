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

package EnsEMBL::Web::Controller::Ajax;

use strict;
use warnings;

use JSON qw(to_json);

sub ajax_s4_gene {
  my $self  = shift;
  my $hub   = $self->hub;

  my ($gene, $db) = $self->_fetch_gene($hub->species, $hub->param('g'));
  my $sd          = $hub->species_defs;
  my $sitename    = $sd->SITE_NAME || $sd->ENSEMBL_SITE_NAME_SHORT;
  my $callback    = $hub->param('jsonpcallback');
  my $response    = { 'release' => { 'version' => $sd->ENSEMBL_VERSION, 'date' => $sd->ENSEMBL_RELEASE_DATE } };

  if ($gene) {

    $hub->param('db', $db); # in case it's needed anywhere and is directly read from url

    my $slice       = $gene->feature_Slice();
    my $object      = $self->new_object('Gene', $gene, {'_hub' => $hub});
    my ($name)      = $object->display_xref;
    my $desc        = $gene->description;
       $desc        =~ s/\s*\[.+// if $desc;
    my $counts      = $object->availability;
    my $r_chr       = $object->seq_region_name;
    my $r_start     = $object->seq_region_start;
    my $r_end       = $object->seq_region_end;
    my $r_len       = $object->feature_length;
    my $r           = sprintf('%s:%d-%d', $r_chr, $r_start, $r_end);
    my $g           = $object->stable_id;
    my $url_params  = {'r' => $r, 'g' => $g, 'db' => $db};
    ($r_start, $r_end) = ($r_end, $r_start) if $r_end < $r_start;

    # Gene information and sequence
    my $info_notes = [];
    {
      my $r_type    = $object->seq_region_type;
      my $tnum      = $counts->{'has_transcripts'} || 0;
      my $enum      = scalar @{$gene->get_all_Exons};
      my $strand    = $object->seq_region_strand;
      my $analysis  = $gene->can('analysis') && $gene->analysis;
         $analysis  = $analysis->description;

      push @$info_notes, sprintf('%s spans %d bps of %s %s from %d to %d.', $name, $r_len, $r_type, $r_chr, $r_start, $r_end);
      push @$info_notes, sprintf('%s has %d transcript%s containing a total of %d exon%s on the %s strand.', $name, $tnum, $tnum == 1 ? '' : 's',  $enum, $enum == 1 ? '' : 's', $strand > 0 ? 'forward' : 'reverse');
      push @$info_notes, $analysis if $analysis;
      push @$info_notes, sprintf('<a href="%s">View the gene sequence in %s.</a>', $self->_full_url({'type' => 'Gene', 'action' => 'Sequence', %$url_params}), $sitename);
      push @$info_notes, sprintf('<a href="%s">View the chromosome region for this gene in %s.</a>', $self->_full_url({'type' => 'Location', 'action' => 'View', %$url_params}), $sitename);
    }

    # Variations
    my $var_notes = [];

    if ($hub->database('variation')) {
      my $snum = scalar @{$slice->get_all_VariationFeatures || []};

      push @$var_notes, sprintf('%s has %s SNP%s.', $name, $snum || 'no', $snum == 1 ? '' : 's');
      push @$var_notes, sprintf(
        '<a href="%s">View sequence variations such as polymorphisms, along with genotypes and disease associations in %s.</a>',
        $self->_full_url({'type' => 'Gene', 'action' => 'Variation_Gene', 'function' => 'Image', %$url_params}),
        $sitename
      ) if $snum;
	  }

    # Orthologs and paralogs
    my $orth_notes = [];
    my $para_notes = [];
    {
      my $onum  = $counts->{'has_orthologs'} || 0;
      my $pnum  = $counts->{'has_paralogs'} || 0;

      if ($hub->database('compara')) {

        push @$orth_notes, sprintf('%s has %s orthologue%s in %s', $name, $onum || 'no', $onum == 1 ? '' : 's', $sitename);
        push @$orth_notes, sprintf(
          '<a href="%s">View homology between species inferred from a gene tree in %s.</a>',
          $self->_full_url({'type' => 'Gene', 'action' => 'Compara_Ortholog', %$url_params}),
          $sitename
        ) if $onum;

        push @$para_notes, sprintf('%s has %s paralogue%s in %s', $name, $pnum || 'no', $pnum == 1 ? '' : 's', $sitename);
        push @$para_notes, sprintf(
          '<a href="%s">View homology arising from a duplication event, inferred from a gene tree in %s.</a>',
          $self->_full_url({'type' => 'Gene', 'action' => 'Compara_Paralog', %$url_params}),
          $sitename
        ) if $pnum;
      }
    }

    # Regulation
    my $reg_notes = [];

    if (my $funcgen_db = $hub->database('funcgen')) {

      my $rf_adaptor  = $funcgen_db->get_adaptor('RegulatoryFeature');
      my $rnum        = scalar @{$rf_adaptor->fetch_all_by_Slice($slice) || []};

      push @$reg_notes, sprintf('There %s %s regulatory element%s located in the region of %s.', $rnum == 1 ? 'is' : 'are', $rnum || 'no', $rnum == 1 ? '' : 's', $name);
      push @$reg_notes, sprintf(
        '<a href="%s">View the gene regulatory elements, such as promoters, transcription binding sites, and enhancers in %s.</a>',
        $self->_full_url({'type' => 'Gene', 'action' => 'Regulation', %$url_params}),
        $sitename
      ) if $rnum;
    }

    # Combine all notes and add other info
    $response = {
      %$response,
      'desc'      => $desc || $name || $g,
      'url'       => $self->_full_url({'type' => 'Gene', 'action' => 'Summary', %$url_params}),
      'image_url' => $self->_full_url('Component', {'type' => 'Location', 'action' => 'Multi', 'function' => 'bottom', 'export' => 'png', 'image_width' => 750, %$url_params}),
      'notes'     => []
    };

    push @{$response->{'notes'}}, {'heading' => 'Gene Information and Sequence', 'text' => $info_notes};
    push @{$response->{'notes'}}, {'heading' => 'Variations',   'text' => $var_notes } if $var_notes;
    push @{$response->{'notes'}}, {'heading' => 'Orthologues',  'text' => $orth_notes} if $orth_notes;
    push @{$response->{'notes'}}, {'heading' => 'Paralogues',   'text' => $para_notes} if $para_notes;
    push @{$response->{'notes'}}, {'heading' => 'Regulation',   'text' => $reg_notes } if $reg_notes;
  }

  # print response with required headers
  $hub->apache_handle->headers_out->add('Access-Control-Allow-Origin', '*');
  $hub->apache_handle->content_type($callback ? 'text/javascript; charset=utf-8' : 'application/json; charset=utf-8');
  $hub->apache_handle->print($callback ? sprintf('%s(%s);', $callback, to_json($response)) : to_json($response));
}

sub _fetch_gene {
  my ($self, $species, $g) = @_;

  my $hub = $self->hub;
  my ($gene, $db);

  if ($species && $g) {
    for (qw(core otherfeatures)) {
      my $db_ad = $hub->database($_) or next;
      $db       = $_;
      $gene     = $db_ad->get_GeneAdaptor->fetch_by_stable_id($g) and last;
    }
  }

  return ($gene, $db);
}

sub _full_url {
  my $self  = shift;
  my $hub   = $self->hub;

  return 'http:'.$hub->species_defs->ENSEMBL_BASE_URL.$hub->url(@_);
}

1;

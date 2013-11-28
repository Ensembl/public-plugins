=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::TextSequence;

use strict;

sub tool_buttons {
  my ($self, $blast_seq, $peptide) = @_;
  
  return unless $self->html_format;
  
  my $hub   = $self->hub;
  my $input = $hub->input;
  my %pars  = map { $_ => $input->url_param($_) // '' } $input->url_param;
  
  my $html  = sprintf('
    <div class="other_tool">
      <p><a class="seq_export export" href="%s">Download view as RTF</a></p>
    </div>', 
    $self->ajax_url('rtf', { filename => join('_', $hub->type, $hub->action, $hub->species, $self->object->Obj->stable_id), _format => 'RTF' })
  );
  
  if ($blast_seq && $hub->species_defs->ENSEMBL_BLAST_ENABLED) {
    $html .= sprintf('
      <div class="other_tool">
        <p><a class="seq_blast find" href="#">BLAST this sequence</a></p>
        <form class="external hidden seq_blast" action="%s" method="post">
          <fieldset>
            <input type="hidden" name="query_sequence" value="%s" />
            <input type="hidden" name="query_type" value="%s" />
            %s
          </fieldset>
        </form>
      </div>',
      $hub->url({ type => 'Tools', action => 'Blast' }),
      $blast_seq,
      $peptide ? 'peptide' : 'dna',
      join '', map { $pars{$_} ne '' ? sprintf '<input type="hidden" name="%s" value="%s">', $_, $pars{$_} : () } keys %pars
    );
  }
  
  return $html;
}

1;

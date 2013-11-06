package EnsEMBL::Web::Component::TextSequence;

use strict;

sub tool_buttons {
  my ($self, $blast_seq, $peptide) = @_;
  
  return unless $self->html_format;
  
  my $hub  = $self->hub;
  my $html = sprintf('
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
            %s
          </fieldset>
        </form>
      </div>',
      $hub->url({ type => 'Tools', action => 'Blast' }),
      $blast_seq,
      $peptide ? '<input type="hidden" name="source" value="peptide" /><input type="hidden" name="db_type" value="peptide" />' : ''
    );
  }
  
  return $html;
}

1;
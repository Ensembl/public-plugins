package EnsEMBL::Web::Component::Tools::BlastInputForm;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::ToolsConstants;

use base qw(EnsEMBL::Web::Component::Tools);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $dom           = $self->dom;
  my $type          = 'NCBI';
  my $sd            = $hub->species_defs;
  my $blast_object  = $self->object->generate_analysis_object('Blast');
  my @species       = sort { $a->{'caption'} cmp $b->{'caption'} } map { value => $_, caption => $sd->species_label($_, 1) }, $sd->valid_species;
  push (@species, { value => 'Test', caption => 'test'});

  my ($dbs, $methods, $default_db, $default_me) = $blast_object->get_blast_form_params;

  my $form = $self->new_form({
    id              => 'blast_input',
    action          => {qw(type Tools action Submit)},
    method          =>  'post',
    class           => 'blast',
    skip_validation => 1
  });
  my $fieldset = $form->add_fieldset;

  $fieldset->set_attribute('class', 'blast_input');

  $fieldset->add_hidden({
    name            => 'blast_type',
    value           => $type
  });

  $fieldset->add_field({
    type            => 'text',
    name            => 'query_sequence',
    label           => 'Either paste sequence data',
    class           => 'query_sequence'
  });

  $fieldset->add_field({
    type            => 'file',
    name            => 'file',
    label           => 'Or upload sequence file',
    class           => 'file'
  });

  $fieldset->add_field({
    type            => 'string',
    label           => "Or enter a sequence ID or accession <br />(EnsEMBL, EMBL, UniProt, RefSeq)",
    name            => 'retrieve_accession',
    class           => 'retrieve_accession',
    size            => '40'
  });

  $fieldset->add_field({
    type            => 'radiolist',
    name            => 'query',
    class           => 'query',
    label           => 'Query type',
    value           => 'dna',
    values          => [
      { value => 'dna',     caption => 'DNA sequence' },
      { value => 'protein', caption => 'Protein sequence' },
    ]
  });

  $fieldset->add_field({
    type            => 'dropdown',
    name            => 'species',
    label           => "Search against",
    class           => 'species',
    values          => \@species,
    value           => $hub->species || ''
  });

  $fieldset->add_field({
    type            => 'radiolist',
    class           => 'db_type',
    name            => 'db_type',
    value           =>  'dna',
    values          => [
      { value => 'dna',     caption => 'DNA database' },
      { value => 'protein', caption => 'Protein database' },
    ]
  });

  $fieldset->add_field({
    type            => 'dropdown',
    name            => 'db_name',
    class           => 'db_name',
    value           =>  $default_db,
    values          =>  $dbs,
  });

  $fieldset->add_hidden({
    name            => 'analysis',
    value           => 'Blast',
  });

  $fieldset->add_field({
    label           => 'Select search tool',
    type            => 'dropdown',
    name            => 'blastmethod',
    class           => 'blastmethod',
    values          => $methods,
    value           => $default_me,
  });

  $fieldset->add_field({
    label           => 'Description (optional):',
    type            => 'string',
    name            => 'description',
    class           => 'desc',
    size            => '160',
  });

  ### Advanced config options ###

  my $show          = $hub->get_cookie_value('toggle_blast') eq 'open';
  my $configuration = $dom->create_element('div', {
    class       => 'config',
    children    => [{
      node_name   => 'a',
      rel         => 'blast',
      class       => ['toggle', 'set_cookie', $show ? 'open' : 'closed'],
      href        => '#Configuration',
      title       => 'Click to see configuration options',
      inner_HTML  => 'Configuration Options'
    }]
  });

  $form->append_child($configuration);

  my %blast_constants = EnsEMBL::Web::ToolsConstants::BLAST_CONFIGURATION_OPTIONS;
  my $options_and_defaults = $blast_constants{'options_and_defaults'};

  $fieldset = $form->add_fieldset;

  $fieldset->set_attributes({ id => 'blast', 'class' => ['config', 'toggleable', $show ? () : 'hidden']});

  foreach my $type ('general', 'scoring', 'filters_and_masking') {
    my $label = ucfirst $type ." options:";
       $label =~s/_/ /g;

    $fieldset->append_child('h2', { class => 'config', inner_HTML => $label });

    foreach ( @{$options_and_defaults->{$type}} ) {
      my ($option, $methods) = @$_;
      my ($show, $default);
      if ($methods->{lc $default_me}) {
        $show     = 1;
        $default  = $methods->{lc $default_me};
      } elsif ($methods->{'all'}) {
        $show     = 1;
        $default  = $methods->{'all'};
      }

      my $element = $blast_constants{$type}->{$option};
      $element->{'value'}       = $default;
      $element->{'class'}       = ['config_' . $option, $element->{'type'} eq 'string' ? ' inactive' : ()];
      $element->{'field_class'} = $show ? 'blast_config_' . $option : 'hide blast_config_' . $option;
      $fieldset->add_field($element);
    }
  }

  $form->add_fieldset->add_field({
    type            => 'Submit',
    name            => 'submit_blast',
    value           => 'Run &rsaquo;',
    class           => 'submit_blast',
  });

  return sprintf '<div><h2>New BLAT or BLAST Search:</h2><input type="hidden" class="panel_type" value="BlastForm" />%s</html>', $form->render;
}

1;


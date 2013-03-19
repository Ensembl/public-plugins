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
  my $self = shift; 
  my $hub = $self->hub; 
  my $html = '<div style="width:932px"><h2>New BLAT or BLAST Search:</h2>';
  $html .= '<input type="hidden" class="panel_type" value="BlastForm" />';
  $html .= '<br />'; 
 
  my $form = EnsEMBL::Web::Form->new({
    id     => 'blast_input',
    action => '/Tools/Submit', 
    method =>  'post', 
    class  => 'blast', 
    validate => 0
  });  

  my $type = 'NCBI';  
  $form->add_hidden({ name => 'blast_type', value => $type });
  $form->add_element( type => 'Text', name => 'query_sequence', label => 'Either paste sequence data', class => 'query_sequence' );
  $form->add_element( type => 'File', name => 'file', label => 'Or upload sequence file', class => 'file' );

  $form->add_element( 
    type  => 'String', 
    label => "Or enter a sequence ID or accession <br />(EnsEMBL, EMBL, UniProt, RefSeq)",
    name  =>'retrieve_accession',
    class => 'retrieve_accession',
    size  => '40',  
  );


  my $current_species = $hub->species;
  my @species;
  foreach my $sp ($hub->species_defs->valid_species) {
    push @species, { value => $sp, name => $hub->species_defs->species_label($sp, 1) };
  }
  @species = sort { $a->{'name'} cmp $b->{'name'} } @species;

  push (@species, { value => 'Test', name => 'test'});
  my $blast_object = $self->object->generate_analysis_object('Blast');
  my ($dbs, $methods, $default_db, $default_me) =  $blast_object->get_blast_form_params(); 

  $form->add_element( 
    type    => 'RadioGroup',  
    name    => 'query', 
    class   => 'query',
    label   => 'Query type',
    value   => 'dna', 
    values  => [
      { value => 'dna',     name => 'DNA sequence' },
      { value => 'protein', name =>'Protein sequence' },
    ] 
  ); 

  $form->add_element(
    type    => 'DropDown',
    name    => 'species',
    label   => "Search against",
    class   => 'species',
    values  => \@species,
    value   => $current_species,
    select  => 'select',
  );


  $form->add_element(   
    type  => 'RadioGroup',
    class => 'db_type',
    name  => 'db_type',
    value =>  'dna',
    values => [
      { value => 'dna',     name => 'DNA database' },
      { value => 'protein', name => 'Protein database' },  
    ]
  );

  $form->add_element (
    type    => 'DropDown',
    name    => 'db_name',
    class   => 'db_name',
    value   =>  $default_db,
    values  =>  $dbs,
    select  => 'select',
  );

  $form->add_element(
    type    => 'Hidden',
    name    => 'analysis',
    value   => 'Blast',
  );

  $form->add_element(
    label   => 'Select search tool',
    type    => 'DropDown',
    name    => 'blastmethod',
    class   => 'blastmethod',
    values  => $methods,
    select  => 'select',
    value   => $default_me,
  );

  $form->add_element(
    label   => 'Description (optional):',
    type    => 'String',
    name    => 'description',
    class   => 'desc',
    value   =>  undef,
    size    => '160',
  );

  $form->add_element(
    type    => 'Submit',
    name    => 'submit_blast',
    value   => 'Run >',
    class   => 'submit_blast',
  );

### Advanced config options ###

  my $show    = $hub->get_cookie_value('toggle_blast') eq 'open';
  my $style   = $show ? '' : 'display:none';

  my $configuration = sprintf('<a rel="blast" class="toggle set_cookie %s" style="border-bottom-width:%s" href="#" title="Click to see configuration options">Configuration Options</a>',
                     $show ? 'open' : 'closed',
                     $show ? '0px' : '2px'  
                    );

  $form->add_notes($configuration)->set_attribute('class', 'config');

  my %blast_constants = EnsEMBL::Web::ToolsConstants::BLAST_CONFIGURATION_OPTIONS;
  my $options_and_defaults = $blast_constants{'options_and_defaults'};

  $form->add_element('type' => 'SubHeader')->set_attributes({ id => 'blast', 'class' =>'config toggleable', 'style' => $style});


  for ('general', 'scoring', 'filters_and_masking'){
    my $type = $_;
    my $label = ucfirst $_ ." options:";
    $label =~s/_/ /g;
    $form->add_notes({'text' => "<h2 class='config'>$label</h2>"});


    foreach ( @{$options_and_defaults->{$type}}){ 
      my ($option, $methods) = @{$_};
      my ($show, $default);
      if ($methods->{lc($default_me)}){
        $show = 1;  
        $default = $methods->{lc($default_me)};
      } elsif ($methods->{'all'}){
        $show = 1;
        $default = $methods->{'all'};
      }

      my $element = $blast_constants{$type}->{$option}; 
      $element->{'value'} = $default;
      my $class = 'config_' . $option;
      $class .= $element->{'type'} eq 'String' ? ' inactive' : '';
      $element->{'class'} = $class;
      $form->add_element(%$element)->set_attribute('class', $show ? 'blast_config_' . $option : 'hide blast_config_' . $option);
    }
  }

################################

  $html .= $form->render;
  $html .= '</div>';

  return $html;
}

1;


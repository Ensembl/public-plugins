package EnsEMBL::Web::ViewConfig::Gene::Compara_Tree;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Constants;

my @groups = 
  ("mammals", "primates", "glires", "laurasiatheria",
   "low-coverage", "saurias", "fish", "cionas", "diptera");

sub init {
  my ($view_config) = @_;
  $view_config->_set_defaults(qw(
    image_width          800
    width                800
    collapsability       gene
    colouring            background
    text_format          msf
    tree_format          newick_mode
    newick_mode          full_web
    nhx_mode             full
    scale                150

    group_fish            default
    group_fish_taxa       7955_8090_31033_69293_99883
    group_fish_fgcolour   royalblue4
    group_fish_bgcolour   lightblue1

    group_saurias           default
    group_saurias_taxa      28377_9031_59729
    group_saurias_fgcolour  yellow4
    group_saurias_bgcolour  lemonchiffon

    group_vertebrates           default
    group_vertebrates_taxa      7719_51511_7955_8090_31033_69293_99883_28377_9031_59729_9258_9315_9358_9361_9365_9371_9478_9544_9593_9598_9600_9606_9615_9685_9739_9785_9796_9813_9913_9978_9986_10020_10090_10116_10141_13616_30538_30608_30611_37347_42254_43179_59463_132908_8364_9483_9823
    group_vertebrates_fgcolour  tomato3
    group_vertebrates_bgcolour  ffe0f0

    group_cionas           default
    group_cionas_taxa      7719_51511

    group_low-coverage      default
    group_low-coverage_taxa 9315_9358_9361_9365_9371_9478_9593_9685_9739_9785_9813_9978_9986_10020_30538_30608_30611_37347_42254_43179_59463_132908

    group_diptera          default
    group_diptera_taxa     7159_7227_7165
    group_diptera_fgcolour 604000
    group_diptera_bgcolour ffd5d5

    group_mammals          default
    group_mammals_taxa      9258_9315_9358_9361_9365_9371_9478_9544_9593_9598_9600_9606_9615_9685_9739_9785_9796_9813_9913_9978_9986_10020_10090_10116_10141_13616_30538_30608_30611_37347_42254_43179_59463_132908_9483_9823
    group_mammals_fgcolour 005000
    group_mammals_bgcolour d0fad0

    group_primates          default
    group_primates_taxa     9478_9544_9593_9598_9600_9606_30608_30611_9483
    group_primates_fgcolour 000050
    group_primates_bgcolour f0f0ff

    group_glires           default
    group_glires_taxa      9978_9986_10020_10090_10116_10141_43179
    group_glires_fgcolour  403000
    group_glires_bgcolour  fff0e0

    group_laurasiatheria           default
    group_laurasiatheria_taxa      9615_9365_59463_42254_9796_9913_9685_9739_30538_132908_9823
    group_laurasiatheria_fgcolour  005050
    group_laurasiatheria_bgcolour  d0fafa

  ));
#  $view_config->add_image_configs({qw( genetreeview nodas)});
  $view_config->storable = 1;
}

sub form {
  my( $view_config, $object ) = @_;
  our %formats = EnsEMBL::Web::Constants::ALIGNMENT_FORMATS;

  $view_config->add_fieldset('Image options');
  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'collapsability',
    'label'    => "Viewing options for tree image",
    'values'   => [ { 'value' => 'gene',
                      'name' => 'View current gene only' },
                    { 'value' => 'paralogs',
                      'name' => 'View paralogs of current gene' },
                    { 'value' => 'duplications',
                      'name' => 'View all duplication nodes' },
                    { 'value' => 'all',
                      'name' => 'View fully expanded tree' } ]
      });


  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'colouring',
    'label'    => "Colour tree according to taxonomy",
    'values'   => [ { 'value' => 'none',
                      'name' => 'No colouring' },
                    { 'value' => 'background',
                      'name' => 'Background' },
                    { 'value' => 'foreground',
                      'name' => 'Foreground' } ]
      });


  foreach my $group (@groups) {
    $view_config->add_form_element({
      'type'     => 'DropDown', 'select'   => 'select',
      'required' => 'yes',      'name'     => "group_$group",
      'label'    => "Display options for $group",
      'values'   => [ { 'value' => 'default',
                        'name' => 'Default behaviour' },
                      { 'value' => 'hide',
                        'name' => 'Hide genes' },
                      { 'value' => 'collapse',
                        'name' => 'Collapse genes' } ]
        });
  }


 $view_config->add_fieldset('Text aligment output options');
  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'text_format',
    'label'    => "Output format for sequence alignment",
    'values'   => [ map { { 'value' => $_,'name' => $formats{$_} } } sort keys %formats ]
  });

  $view_config->add_fieldset('Text tree output options');
  %formats =  EnsEMBL::Web::Constants::TREE_FORMATS;
  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'tree_format',
    'label'    => "Output format for tree",
    'values'   => [ map { { 'value' => $_,'name' => $formats{$_}{'caption'} } } sort keys %formats ]
  });

  $view_config->add_form_element({
    'type'     => 'PosInt', 
    'required' => 'yes',      'name'     => 'scale',
    'label'    => "Scale size for Tree text dump",
  });

  %formats =  EnsEMBL::Web::Constants::NEWICK_OPTIONS;
  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'newick_mode',
    'label'    => "Mode for Newick tree dumping",
    'values'   => [ map { { 'value' => $_,'name' => $formats{$_} } } sort keys %formats ]
  });

  %formats =  EnsEMBL::Web::Constants::NHX_OPTIONS;
  $view_config->add_form_element({
    'type'     => 'DropDown', 'select'   => 'select',
    'required' => 'yes',      'name'     => 'nhx_mode',
    'label'    => "Mode for NHX tree dumping",
    'values'   => [ map { { 'value' => $_,'name' => $formats{$_} } } sort keys %formats ]
  });
}

1;

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped) = @_;
  my $species_defs  = $self->hub->species_defs;

  my $set_order = [qw(primates rodents laurasia placental sauria fish all)];
  my %orthologue_map = qw(SEED BRH PIP RHS);

  my $species_sets = {
    'primates'  =>  {'title' => 'Primates', 'desc' => '', 'species' => []},
    'rodents'   =>  {'title' => 'Rodents',  'desc' => '', 'species' => []},
    'laurasia'  =>  {'title' => 'Laurasiatheria', 'desc' => 'Carnivores, ungulates and insectivores',  'species' => []},
    'placental' =>  {'title' => 'Placental Mammals', 'desc' => '', 'species' => []},
    'sauria'    =>  {'title' => 'Sauropsida', 'desc' => 'Birds and Reptiles', 'species' => []},
    'fish'      =>  {'title' => 'Fish', 'desc' => '', 'species' => []},
    'all'       =>  {'title' => 'All', 'desc' => 'All species, including invertebrates', 'species' => []},
  };

  my $sets_by_species = {};

  my $ortho_type;
  foreach my $species (keys %$orthologue_list) {
    next if $skipped->{$species};
    my $no_ortho = 0;
    my $group = $species_defs->get_config($species, 'SPECIES_GROUP');
    push @{$species_sets->{'all'}{'species'}}, $species;
    my $sets = [];

    my $orthologues = $orthologue_list->{$species} || {};
    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}{$stable_id};
      my $orth_desc = ucfirst($orthologue_map{$orth_info->{'homology_desc'}} || $orth_info->{'homology_desc'});
      $species_sets->{'all'}{$orth_desc}++;
      $ortho_type->{$species}{$orth_desc} = 1;
    }
    if (!$ortho_type->{$species}{'1-to-1'} && !$ortho_type->{$species}{'1-to-many'}
          && !$ortho_type->{$species}{'Many-to-many'}) {
      $no_ortho = 1;
      $species_sets->{'all'}{'none'}++;
    }
    if ($group eq 'Primates') {
      push @{$species_sets->{'primates'}{'species'}}, $species;
      push @$sets, 'primates';
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'primates'}{$k} += $v;
      }
      $species_sets->{'primates'}{'none'}++ if $no_ortho;
    }
    if ($group eq 'Euarchontoglires') {
      push @$sets, 'rodents';
      push @{$species_sets->{'rodents'}{'species'}}, $species;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'rodents'}{$k} += $v;
      }
      $species_sets->{'rodents'}{'none'}++ if $no_ortho;
    }
    if ($group eq 'Laurasiatheria') {
      push @$sets, 'laurasia';
      push @{$species_sets->{'laurasia'}{'species'}}, $species;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'laurasia'}{$k} += $v;
      }
      $species_sets->{'laurasia'}{'none'}++ if $no_ortho;
    }
    if ($group =~ /Primates|Euarchontoglires|Laurasiatheria|Xenarthra|Afrotheria/) {
      push @$sets, 'placental';
      push @{$species_sets->{'placental'}{'species'}}, $species;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'placental'}{$k} += $v;
      }
      $species_sets->{'placental'}{'none'}++ if $no_ortho;
    }
    if ($group eq 'Sauropsida') {
      push @$sets, 'sauria';
      push @{$species_sets->{'sauria'}{'species'}}, $species;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'sauria'}{$k} += $v;
      }
      $species_sets->{'sauria'}{'none'}++ if $no_ortho;
    }
    if ($group eq 'Euteleostomi') {
      push @$sets, 'fish';
      push @{$species_sets->{'fish'}{'species'}}, $species;
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
        $species_sets->{'fish'}{$k} += $v;
      }
      $species_sets->{'fish'}{'none'}++ if $no_ortho;
    }
    $sets_by_species->{$species} = $sets;
  }
  $species_sets->{'primates'}{'desc'} = 'Human and '. (scalar(@{$species_sets->{'primates'}{'species'}})-1)
                                          .' other primates';
  $species_sets->{'rodents'}{'desc'} = 'Mouse, rat and '. (scalar(@{$species_sets->{'rodents'}{'species'}})-2)
                                          .' other rodents';
  $species_sets->{'placental'}{'desc'} = (scalar(@{$species_sets->{'placental'}{'species'}}))
                                          .' placental mammalian species';
  $species_sets->{'fish'}{'desc'} = 'Zebrafish and '. (scalar(@{$species_sets->{'fish'}{'species'}})-1)
                                          .' other ray-finned fish';

  return ($species_sets, $sets_by_species, $set_order);
}

1;

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped) = @_;
  my $species_defs  = $self->hub->species_defs;

  my $set_order = [qw(primates rodents laurasia placental sauria fish all)];
  my %orthologue_map = qw(SEED BRH PIP RHS);

  my $species_sets = {
    'primates'  =>  {'title' => 'Primates', 'desc' => 'Humans and other primates', 'species' => []},
    'rodents'   =>  {'title' => 'Rodents',  'desc' => 'Rodents, rabbits and related species', 'species' => []},
    'laurasia'  =>  {'title' => 'Laurasiatheria', 'desc' => 'Carnivores, ungulates and insectivores',  'species' => []},
    'placental' =>  {'title' => 'Placental Mammals', 'desc' => 'All placental mammals', 'species' => []},
    'sauria'    =>  {'title' => 'Sauropsida', 'desc' => 'Birds and Reptiles', 'species' => []},
    'fish'      =>  {'title' => 'Fish', 'desc' => 'Ray-finned fishes', 'species' => []},
    'all'       =>  {'title' => 'All', 'desc' => 'All species, including invertebrates', 'species' => []},
  };

  my $sets_by_species = {};

  my ($ortho_type);
  my @A = keys %$orthologue_list;

  foreach my $species ($species_defs->valid_species) {
    next if $skipped->{$species};
    my $group = $species_defs->get_config($species, 'SPECIES_GROUP');
    push @{$species_sets->{'all'}{'species'}}, $species;
    my $sets = [];
    my $orthologues = $orthologue_list->{$species} || {};
    my $no_ortho = 0;
    if (!$orthologue_list->{$species} && $species ne $self->hub->species) {
      $no_ortho = 1;
    }

    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}{$stable_id};
      my $orth_desc = ucfirst($orthologue_map{$orth_info->{'homology_desc'}} || $orth_info->{'homology_desc'});
      $species_sets->{'all'}{$orth_desc}++;
      $ortho_type->{$species}{$orth_desc} = 1;
    }

    if ($species ne $self->hub->species && !$ortho_type->{$species}{'1-to-1'} && !$ortho_type->{$species}{'1-to-many'}
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

  return ($species_sets, $sets_by_species, $set_order);
}

1;

package EnsEMBL::Ensembl::Document::HTML::AssemblyTable;

use strict;
use warnings;

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Data::Release;
use EnsEMBL::Web::Data::Species;
use EnsEMBL::Web::Data::ReleaseSpecies;

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $this_release = $SD->ENSEMBL_VERSION;
  my $archives = $SD->ENSEMBL_ARCHIVES;

  my $first_archive = [sort keys %$archives]->[0];

  ## get assembly info for each species
  my @species = EnsEMBL::Web::Data::Species->find_all;
  my @releases = EnsEMBL::Web::Data::Release->search({ release_id => { '>=' => $first_archive } }, { order_by => 'release_id desc' });
  my @release_species = EnsEMBL::Web::Data::ReleaseSpecies->search({ release_id => { '>=' => $first_archive } });

  ## Split the table in two so it isn't too wide
  my $release_break = int(($this_release - $first_archive)/2);

  my $split_releases = [ [ splice (@releases, 0, $release_break) ], \@releases ];

  my $release_to_species = {};
  $release_to_species->{$_->species_id}{$_->release_id} = $_ for (@release_species);

  my $html = render_assembly_table($split_releases->[0], \@species, $release_to_species);
  $html .= "<br />";
  $html .= render_assembly_table($split_releases->[1], \@species, $release_to_species);
  
  return $html;
}

sub render_assembly_table {
  my ($releases, $species, $release_species) = @_;

  my $header = '<tr>
    <th style="width:20%">Species</th>
  ';
  my $body = "";

  my ($date, $version, $order, $species_name, $row, $rs, $cells, $assembly_name, $current_name, $class);

  my $c = { -1 => 'bg4', 1 => 'bg2', x => 1 }; # CSS class flip-flop for tds

  my $style = sprintf( ' style="width:%0.3f%%"', 80 / @$releases );
  foreach my $rel (@$releases) {
    $date = $rel->online eq 'Y' ? qq{<a href="http://} . $rel->archive . qq{.archive.ensembl.org">} . $rel->shorter_date . "</a>" : $rel->shorter_date;

    $header .= "<th$style>$date<br />v".$rel->id."</th>";
  }

  $header .= "</tr>\n";
  
  (my $short_header = $header) =~ s/<br \/>.+?<\/th>//g; # Like the header, but without release numbers
 
  my @rows = ();
 
  foreach my $s (sort { $a->{'name'} cmp $b->{'name'} } @$species) {
    ($species_name = $s->name) =~ s/_/ /g;
    $cells = {};
    $assembly_name = "";
    $current_name = "";
    $order = 1;
    
    $c->{'x'} = 1; # Reset the flip-flop

    $row = "<tr><th>" . ( $s->online eq 'Y' ? qq{<a href="http://www.ensembl.org/} . $s->name . qq{"><i>$species_name</i></a>} : "<i>$species_name</i>" ) . "</th>";

    foreach my $r (@$releases)  {
      $rs = $release_species->{$s->id}->{$r->id};
      $assembly_name = $rs ? $rs->assembly_name : "";

      $order++ if ($current_name ne $assembly_name);

      $cells->{$order} ||= { name => $assembly_name, count => 0 };
      $cells->{$order}->{'count'}++;

      $current_name = $assembly_name;
    }

    # Don't print empty row
    next if !$cells->{$order}->{'name'} && $cells->{$order}->{'count'} == scalar @$releases;

    foreach my $td (sort keys %$cells) {
      $class = $cells->{$td}->{'name'} ? $c->{$c->{'x'}*=-1} : "";
      $row .= qq{<td colspan="$cells->{$td}->{'count'}" class="$class">$cells->{$td}->{'name'}</td>};
    }
 
    $row .= "</tr>\n";

    push (@rows, $row);
  }

  my $species_total = scalar @rows;
  my $divisor = int($species_total / 15) + 1;
  my $breakpoint = $species_total % $divisor ? int($species_total / $divisor) + 1 : $species_total / $divisor;
  my $j = 0;

  # Insert the short header every [$breakpoint] rows ($j keeps track of the added rows)
  for (my $i = $breakpoint; $i < scalar @rows; $i += $breakpoint) {
    splice (@rows, $i+$j++, 0, $short_header);
  }

  $body = join ('', @rows); 
  $body .= $short_header if $species_total % $divisor;

  return qq{\n<table style="margin:auto; width:95%" border="1" class="ss">\n$header\n$body\n</table>};
}

1;

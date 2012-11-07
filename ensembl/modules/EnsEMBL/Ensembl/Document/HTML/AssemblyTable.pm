package EnsEMBL::Ensembl::Document::HTML::AssemblyTable;

use strict;

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::DBSQL::WebsiteAdaptor;

sub render {
  my ($class, $request) = @_;

  my $hub = EnsEMBL::Web::Hub->new;

  my $SD = $hub->species_defs;
  my $this_release = $SD->ENSEMBL_VERSION;
  my $archives = $SD->ENSEMBL_ARCHIVES;

  my $first_archive = [sort keys %$archives]->[0];

  my $adaptor = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub);

  ## get assembly info for each species
  my $species = $adaptor->fetch_all_species;
  my @releases = sort { $b->{'id'} <=> $a->{'id'} } @{$adaptor->fetch_releases};
  my @archives = @{$adaptor->fetch_archives($first_archive)};

  my @archive_releases;
  foreach (@releases) { 
    if ($_->{'id'} >= $first_archive) {
      push @archive_releases, $_; 
    }
  }

  ## Split the table in two so it isn't too wide
  my $release_break = int(scalar(@archive_releases)/2);

  my $split_releases = [ [ splice (@archive_releases, 0, $release_break) ], \@archive_releases ];

  my $release_to_species = {};
  foreach (@archives) {
    $release_to_species->{$_->{'species_id'}}{$_->{'id'}} = $_->{'assembly'};
  }

  return render_assembly_table($split_releases->[0], $species, $release_to_species).render_assembly_table($split_releases->[1], $species, $release_to_species);
}

sub render_assembly_table {
  my ($releases, $species, $release_species) = @_;
  return unless @$releases;

  my $header = '<tr>
    <th style="width:20%">Species</th>
  ';
  my $body = "";

  my ($date, $version, $order, $species_name, $row, $rs, $cells, $assembly_name, $current_name, $online, $class);

  my $c = { -1 => 'bg4', 1 => 'bg2', x => 1 }; # CSS class flip-flop for tds

  my $style = sprintf( ' style="width:%0.3f%%"', 80 / @$releases );
  foreach my $rel (@$releases) {
    $date = $rel->{'online'} eq 'Y' ? qq{<a href="http://} . $rel->{'archive'} . qq{.archive.ensembl.org">} . $rel->{'date'} . "</a>" : $rel->{'date'};

    $header .= "<th$style>$date<br />v".$rel->{'id'}."</th>";
  }

  $header .= "</tr>\n";
  
  (my $short_header = $header) =~ s/<br \/>.+?<\/th>/<\/th>/g; # Like the header, but without release numbers
 
  my @rows = ();
 
  foreach my $s (sort { $a->{'name'} cmp $b->{'name'} } @$species) {
    ($species_name = $s->{'name'}) =~ s/_/ /g;
    $cells = {};
    $assembly_name = "";
    $current_name = "";
    $online = $s->{'online'} || 'N';
    $order = 1;
    
    $c->{'x'} = 1; # Reset the flip-flop

    $row = "<tr><th>" . ( $online eq 'Y' ? qq{<a href="http://www.ensembl.org/} . $s->{'name'} . qq{"><i>$species_name</i></a>} : "<i>$species_name</i>" ) . "</th>";

    foreach my $r (@$releases)  {  
      $assembly_name = $release_species->{$s->{'id'}}->{$r->{'id'}} || 'none';

      $order++ if ($current_name ne $assembly_name);
      $current_name = $assembly_name;
      $assembly_name = '' if $assembly_name eq 'none';

      $cells->{$order} ||= { name => $assembly_name, count => 0 };
      $cells->{$order}->{'count'}++;
    }

    # Don't print empty row
    next if !$cells->{$order}->{'name'} && $cells->{$order}->{'count'} == scalar @$releases;

    foreach my $td (sort keys %$cells) {
      $class = $cells->{$td}->{'name'} ? $c->{$c->{'x'}*=-1} : "";
      $row .= qq(<td colspan="$cells->{$td}->{'count'}" class="$class">$cells->{$td}->{'name'}</td>);
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
    next if $i+$j+1 > scalar @rows;
    splice (@rows, $i+$j++, 0, $short_header);
  }

  $body = join ('', @rows); 
  $body .= $short_header if $species_total % $divisor;

  return qq{\n<table class="ss">\n$header\n$body\n</table>};
}

1;

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

package EnsEMBL::Ensembl::Document::HTML::AssemblyTable;

use strict;

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::DBSQL::ArchiveAdaptor;

sub render {
  my ($class, $request) = @_;

  my $html = qq(
<p><b>Key</b>: 
<span class="hilite" style="padding:0 10px;border:1px solid #999;">&nbsp;</span> New species
<span class="bg2" style="padding:0 10px;margin-left:2em;border:1px solid #999;">&nbsp;</span> or
<span class="bg4" style="padding:0 10px;border:1px solid #999;">&nbsp;</span> Species present in archive 
<span style="padding:0 10px;margin-left:2em;border:1px solid #999;">&nbsp;</span> Species not in this version of Ensembl 
);

  my $hub = EnsEMBL::Web::Hub->new;

  my $SD = $hub->species_defs;
  my $this_release = $SD->ENSEMBL_VERSION;
  my $archives = $SD->ENSEMBL_ARCHIVES;

  my $first_archive = [sort keys %$archives]->[0];

  my $adaptor = EnsEMBL::Web::DBSQL::ArchiveAdaptor->new($hub);

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

  $html .= render_assembly_table($split_releases->[0], $species, $release_to_species, 1).render_assembly_table($split_releases->[1], $species, $release_to_species, 2);
  return $html;
}

sub render_assembly_table {
  my ($releases, $species, $release_species, $table_count) = @_;
  return unless @$releases;

  my $header = '<tr>
    <th style="width:20%">&nbsp;</th>
  ';
  my $body = "";

  my ($date, $version, $order, $species_name, $common, $row, $rs, $cells, $assembly_name, $current_name, $online, $class);

  my $c = { -1 => 'bg4', 1 => 'bg2', x => 1 }; # CSS class flip-flop for tds

  my $style = sprintf( ' style="width:%0.3f%%"', 80 / @$releases );
  foreach my $rel (@$releases) {
    my $short_date = $rel->{'archive'};
    $short_date =~ s/20/ 20/;
    $date = $rel->{'online'} eq 'Y' ? qq{<a href="http://} . $rel->{'archive'} . qq{.archive.ensembl.org">} . $short_date . "</a>" : $short_date;

    $header .= "<th$style>$date<br />v".$rel->{'id'}."</th>";
  }

  $header .= "</tr>\n";
  
  my @rows = ();
 
  my $top_border = 'style="border-style:solid;border-color:#ccc;border-width:1px 0 0 0"';
  my $two_borders = 'style="border-style:solid;border-color:#ccc;border-width:1px 0 0 1px"';
  foreach my $s (sort { $a->{'name'} cmp $b->{'name'} } @$species) {
    ($species_name = $s->{'name'}) =~ s/_/ /g;
    $common = $s->{'common_name'};
    $cells = {};
    $assembly_name = "";
    $current_name = "";
    $order = 1;
    
    $c->{'x'} = 1; # Reset the flip-flop

    my $name_string = "<i>$species_name</i>";
    $name_string .= " ($common)" unless $common =~ /\./;
    $row = sprintf('<tr><th><a href="/%s/"><i>%s</i></a>', $s->{'name'}, $species_name);
    $row .= " ($common)" unless $common =~ /\./;
    $row .= '</th>';

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

    my $i = 0;
    foreach my $td (sort keys %$cells) {
      my $border = $i > 0 ? $two_borders : $top_border;
      if ($table_count == 1
            && $i == 0 
            && !$cells->{$td+1}->{'name'} 
            && $cells->{$td}->{'count'} == 1) {
        $class = 'hilite'; ## new species
      }
      elsif ($cells->{$td}->{'name'}) {
        $class = $c->{$c->{'x'}*=-1};
      }
      else {
        $class = '';
      }
      $row .= qq(<td colspan="$cells->{$td}->{'count'}" class="$class"$border>$cells->{$td}->{'name'}</td>);
      $i++;
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
    splice (@rows, $i+$j++, 0, $header);
  }

  $body = join ('', @rows); 
  $body .= $header if $species_total % $divisor;

  return qq{\n<table class="ss" style="margin-bottom:2em">\n$header\n$body\n</table>};
}

1;

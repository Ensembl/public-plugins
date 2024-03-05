=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

use EnsEMBL::Web::DBSQL::ArchiveAdaptor;

use parent qw(EnsEMBL::Web::Document::HTML);

sub render {
  my ($self, $request) = @_;

  my $html = qq(
<p><b>Key</b>: 
<span class="hilite" style="padding:0 10px;border:1px solid #999;">&nbsp;</span> New species
<span class="bg2" style="padding:0 10px;margin-left:2em;border:1px solid #999;">&nbsp;</span> or
<span class="bg4" style="padding:0 10px;border:1px solid #999;">&nbsp;</span> Species present in archive 
<span style="padding:0 10px;margin-left:2em;border:1px solid #999;">&nbsp;</span> Species not in this version of Ensembl 
);

  my $hub = $self->hub;

  my $SD = $hub->species_defs;
  my $this_release = $SD->ENSEMBL_VERSION;

  ## Get current Ensembl species
  my @species = $SD->reference_species;
  my $spp;

  foreach my $sp (@species) {
    $spp->{$sp} = $SD->get_config($sp, 'SPECIES_DISPLAY_NAME');
  }

  ## get assembly info for each species
  my $adaptor = EnsEMBL::Web::DBSQL::ArchiveAdaptor->new($hub);

  ## We only want the releases after the first current archive
  my $first_archive = 0;
  my @releases;
  my @all_releases = @{$adaptor->fetch_releases};
  foreach (@all_releases) {
    next if $_->{'id'} > 10000;
    $first_archive = $_->{'id'} if (!$first_archive && $_->{'online'} eq 'Y');
    next unless $first_archive;
    ### final list needs to be in descending order
    unshift @releases, $_;
  }

  ## Split the table in two so it isn't too wide
  my $release_break = int(scalar(@releases)/2);

  my $split_releases = [ [ splice (@releases, 0, $release_break) ], \@releases ];

  my $assemblies = $adaptor->fetch_archive_assemblies($first_archive);

  $html .= render_assembly_table($split_releases->[0], $spp, $assemblies, 1).render_assembly_table($split_releases->[1], $spp, $assemblies, 2);
  return $html;
}

sub render_assembly_table {
  my ($releases, $spp, $assemblies, $table_count) = @_;
  return unless @$releases && keys %$assemblies;

  my $border = 'border-style:solid;border-color:#fff;border-width:0 1px 1px 0';
  my $header = qq(<tr>
    <th style="width:20%;$border">&nbsp;</th>
  );
  my $body = "";

  ## Render headers
  my $style = sprintf( ' style="width:%0.3f%%;%s"', 80 / @$releases, $border );
  foreach my $rel (@$releases) {
    my $short_date = $rel->{'archive'};
    $short_date =~ s/20/ 20/;
    my $date = $rel->{'online'} eq 'Y' ? qq{<a href="http://} . $rel->{'archive'} . qq{.archive.ensembl.org">} . $short_date . "</a>" : $short_date;

    $header .= "<th$style>$date<br />v".$rel->{'id'}."</th>";
  }

  $header .= "</tr>\n";
  
  my @rows = ();
  my $c = { -1 => 'bg4', 1 => 'bg2', x => 1 }; # CSS class flip-flop for tds

  foreach my $species (sort { $spp->{$a} cmp $spp->{$b} } keys %$spp) {
    my $common = $spp->{$species};
    my $info = $assemblies->{$species};
    my ($species_header, $assembly_name, $current_name);
    my $cells = {};
    my $order = 1;
    my $row .= '<tr>';
    $c->{'x'} = 1; # Reset the flip-flop

    foreach my $release (@$releases) {
      my $version = $release->{'id'};
      ## Create side header
      unless ($species_header) {
        my $display_name;
        (my $scientific = $species) =~ s/_/ /g;
        if ($common =~ /\./ || $common eq $scientific) { ## "Common" name is abbreviated scientific name
          $display_name = sprintf('<i>%s</i>', $scientific);
        }
        else {
          $display_name = $common;
        }
      
        $species_header = sprintf('<th style="%s"><a href="/%s/">%s</a></th>', $border, $species, $display_name);
        $row .= $species_header;
      }

      ## Create cells
      my $assembly_name = $info->{$version}{'assembly'} || 'none';
      ## We have to have an assembly name or this check fails!
      $order++ if ($current_name ne $assembly_name);

      $current_name = $assembly_name;
      ## Now reset the assembly name to blank, because we don't want to display it!
      $assembly_name = '' if $assembly_name eq 'none';

      $cells->{$order} ||= { name => $assembly_name, count => 0 };
      $cells->{$order}{'count'}++;
    }

    # Don't print empty row
    next if !$cells->{$order}->{'name'} && $cells->{$order}->{'count'} == scalar @$releases;

    my $class;
    my $i = 0;
    my $one_border = 'style="border-style:solid;border-color:#ccc;border-width:0 0 1px 0"';
    my $two_borders = 'style="border-style:solid;border-color:#ccc;border-width:0 0 1px 1px"';
    foreach my $td (sort {$a <=> $b} keys %$cells) {
      my $border = $i > 0 ? $two_borders : $one_border;
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

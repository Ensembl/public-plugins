package EnsEMBL::Ensembl::Document::HTML::AssemblyTable;

use strict;
use warnings;

use EnsEMBL::Web::DBSQL::NewsAdaptor;
use EnsEMBL::Web::RegObj;

{

sub render {
  my ($class, $request) = @_;

  my $SD = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $adaptor = $ENSEMBL_WEB_REGISTRY->newsAdaptor();
  my $this_release = $SD->ENSEMBL_VERSION;
  my $first_archive = $SD->EARLIEST_ARCHIVE;
  my $release_break = int($this_release - (($this_release -$first_archive)/2));
  my $html = render_assembly_table($adaptor, $this_release, $release_break);
  $html .= "<br />";
  $html .= render_assembly_table($adaptor, $release_break-1, $first_archive);
  return $html;
}

sub render_assembly_table {
  my ($wa, $this_release, $release_break) = @_;

  my @release_data =  @{$wa->fetch_releases()};
  my %archive_data =  %{$wa->fetch_archives()};
  my $header_row = qq(<th>Species</th>\n);
  my $header_short = $header_row;
  my %info;

  foreach my $data ( @release_data ) {
    my $release_id = $data->{release_id};
    next if $release_id > $this_release;
    last if $release_id == ($release_break - 1 );
    my $is_online = $archive_data{$release_id} ? 1 : 0;

    (my $link = $data->{short_date}) =~ s/\s+//;
    (my $display_date = $data->{short_date}) =~ s|\s+20||;

    if ($is_online) {
      $header_row   .=qq(<th><a href="http://$link.archive.ensembl.org">$display_date</a><br />v$release_id</th>);
      $header_short .=qq(<th><a href="http://$link.archive.ensembl.org">$display_date</a></th>);
    }
    else {
      $header_row   .=qq(<th>$display_date<br />v$release_id</th>);
      $header_short .=qq(<th>$display_date</th>);
    }

      # If the assembly name spans several releases,%info stores its first release only
    # %info{species}{assembly name} = release num

    foreach my $assembly_info ( @{ $wa->fetch_assemblies($release_id)  }  ) {
      $info{ $assembly_info->{species} }{ $assembly_info->{assembly_name} } = $release_id;
    }

    # Manually add species that have been removed
    $info{"Caenorhabditis_briggsae"}{"removed"} = 27 if $release_id == 27;
    $info{"Caenorhabditis_briggsae"}{"cb25.agp8"} = 25 if $release_id ==25;
    $info{"Apis_mellifera"}{"removed"} = 39 if $release_id ==39;
  }

  ## Work out where we want to put the repeat headers
  my $species_total = keys %info;
  my $divisor = int($species_total / 15) + 1;
  my $breakpoint = $species_total % $divisor ? int($species_total / $divisor) + 1 : $species_total / $divisor;
  my ($count, $repeat);

  my $table =  qq(\n<table style="margin:auto; width:95%" border="1" class="ss">\n<tr>$header_row</tr>\n);;
  foreach my $species (sort keys %info) {
    my @tint = qw(class="bg4" class="bg2");
    (my $display_spp = "<i>$species</i>") =~ s|_| |;
    my %assemblies = reverse %{ $info{$species} };

    my $release_text;
    my $release_counter = $this_release;
    foreach my $release (sort {$b <=> $a} keys %assemblies  ) {
      next unless $assemblies{$release};
      my $colspan = $release_counter - $release;
      $colspan++;# if $release_counter == $this_release;
      $release_counter -= $colspan;
      if ($assemblies{$release} eq 'removed') {
  $release_text .= qq(   <td colspan="$colspan">$assemblies{$release}</td>\n);
      }
      else {
  $release_text .= qq(   <td $tint[0] colspan="$colspan">$assemblies{$release}</td>\n);
      }
      push ( @tint, shift @tint );
    }
    my $link = qq(<a href="http://www.ensembl.org/$species">$display_spp</a>);
    $link = $display_spp if $info{$species}{"removed"};
    $table .="<tr>\n   <th>$link</th>\n$release_text\n</tr>\n\n" if $release_text;
    $count++;
    $repeat++;
    if ($repeat == $breakpoint || $count == $species_total) {
      $table .= $header_short;
      $repeat = 0;
    }
  }

  $table .= qq(</table>\n);
  return $table;
}

}

1;

package EnsEMBL::Lucene::Component::Search::Results;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);

use Data::Dumper;
#$Data::Dumper::Maxdepth=2;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $species_defs = $hub->species_defs;
  my $sitetype = lc($species_defs->ENSEMBL_SITETYPE);
  my $html;

  my $species = $hub->param('species');
  my $display_species = $species eq 'all' ? "the ".ucfirst($sitetype)." website" : $hub->species_defs->get_config($species,'SPECIES_COMMON_NAME');
  my $q = $hub->param('q');

  my $results_by_group = $object->groups;
  my $group_count      = scalar keys %$results_by_group;

  if (   $results_by_group->{'Species'}{'total'} && $results_by_group->{'Feature type'}{'total'} || $results_by_group->{'Help'}{'total'} ) {
    $html = qq(<h3>Your search of $display_species with '$q' returned the following results:</h3>);

    my @group_classes = ('one-col');
    if ( $group_count > 1 ) {
      @group_classes = $group_count > 1
       ? ( 'threecol-left', 'threecol-middle', 'threecol-right' )
       : ( 'twocol-left', 'twocol-right' );
    }

    my $i = 0;

#    foreach my $group_name ( sort { $a cmp $b } keys %$results_by_group ) {
    foreach my $group_name ( 'Feature type', 'Species', 'Help' ) {
      my $class = $group_classes[$i];
      my $group_total = delete $results_by_group->{$group_name}->{total};
      next if $group_total < 1;

      $html .= qq(<div class="$class">
<table class="search_results">
<tr><th colspan="2">By $group_name</th></tr>
<tr><td>Total</td><td>$group_total</td></tr>
      );

      my $group     = $results_by_group->{$group_name}->{results};

      foreach my $child_name ( sort { $group->{$a}{'sort_field'} cmp $group->{$b}{'sort_field'} } keys %{$group} ) {
        my $child = $group->{$child_name};
        $child_name =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
        my $display_n = $child->{'sort_field'};
        $display_n =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
        $display_n =~  s/_/ /g;

        $html .= qq(<tr>
                              <td>);

        $html .= qq(<a href="#" class="collapsible">$display_n</a><ul class="shut">\n);
        my $grandchild  = $child->{results};
        my $child_count = $child->{total};
        my $g_clipped;
        foreach my $g_name ( sort { $grandchild->{$a}{'sort_field'} cmp $grandchild->{$b}{'sort_field'} } keys %{$grandchild} ) {
          my $gchild = $grandchild->{$g_name};
          my $display_n = $gchild->{'sort_field'};
          $display_n =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
          my $g_count = $gchild->{count};
          my $clipped = $gchild->{is_clipped_flag};
          $g_clipped = '>' if $clipped eq '>';
          $g_name =~ s/${sitetype}_(.*)$/ucfirst($1)/e;

          # Handle Docs Urls differently
          my $g_url;
          if ( $g_name =~ /faq|docs|glossary|help/i ) {
            $g_url = "/Search/Details?species=all;idx=" . ucfirst($g_name) . ';q=' . $hub->param('q');
          }
          else {
            my ( $sp, $idx );
            ( $idx, $sp ) = $group_name =~ /species/i ? ( $g_name, $child_name ) : ( $child_name, $g_name );
            $sp     =~ s/\s/_/;
            $g_name =~ s/_/ /g;
            $g_url = "/$sp/Search/Details?species=$sp;idx=$idx;end=$g_count;q=" . $hub->param('q');
          }
          # yet more exceptions for Help and docs
          # change Help -> Page Help, Docs -> Documentation and Faq to FAQ
          # this should be fixed at source i.e. the Search Domain name
          $display_n =~ s/Help/Page Help/;
          $display_n =~ s/Docs/Documentation/;
          $display_n =~ s/Faq/FAQ/;

          $display_n =~  s/_/ /g;

          $html .= qq#<li><a href="$g_url"> $display_n ($clipped$g_count)</a></li>#;
        }
        $html .= "</ul>\n";

        $html .= qq(</td>
 <td style="width:5em"><a href="#"> $g_clipped$child_count</a>
 </tr>\n);
      }

      $html .= qq(</table>\n</div>\n\n);
      $i++;
    }
  }
  else {
    $html = $self->re_search;
  }
  return $html;
}

sub re_search {
  my $self   = shift;
  my $hub = $self->hub;
  my $sitetype = ucfirst(lc($hub->species_defs->ENSEMBL_SITETYPE));
  my $html;

  my $species = $hub->param('species');
  my $display_species = $species eq 'all' ? 'all species' : $hub->species_defs->get_config($species,'SPECIES_COMMON_NAME');
  my $q      = $hub->param('q');
  my $q_name = $q;

  my $do_search = 0;
  if ( $q =~ /^(\S+?)(\d+)/ ) {
    my $ENS = $1;
    my $dig = $2;
    if ( ( $ENS =~ /ENS|OTT/ ) && ( length($dig) != 11 ) && ( $ENS !~ /ENSFM|ENSSNP/ ) ) {
      $do_search = 1;
      my $newq = $ENS . sprintf( "%011d", $dig );
      $html = qq(<h2><p>Your search of $display_species with '$q' returned no results</p></h2>);
      my $url =
        '/' . $hub->species . "/Search/Results?species=$species;idx=" . $hub->param('idx') . ';q=' . $newq;
      $html .=
        sprintf qq(<h3>Would you like to <a href="%s">search using $newq</a> (note number of digits)?</h3>), $url;
      return $html;
    }
  }
  if ( !$do_search && ( $species ne 'all' ) ) {
    $species =~ s/_/ /g;
    $html .= '<div style="font-size:1.2em">';
    $html .= qq(<p class="space-below">Your search of <strong>$display_species annotation</strong> for the term '$q' returned no results.</p>);
    my $url = '/' . $hub->species . '/Search/Results?species=all;idx=' . $hub->param('idx') . ';q=' . $q;
    $html .= sprintf qq(<p class="space-below"><strong>Would you like to <a href="%s">search the rest of the website</a> with this term ?</strong></p>), $url;
    $html .= '</div>';
    return $html;
  }

  $html = qq(<h2>Your search of the $sitetype website for the term '$q' returned no results</h2>);
  $html .=
qq(<h3>If you are expecting to find features with this search term and think the failure to do so is an error, please <a href="/Help/Contact" class="popup">contact helpdesk</a> and let us know</h3>);
  warn "Found nothing when searching for \"$q\"";
  return $html;
}

1;


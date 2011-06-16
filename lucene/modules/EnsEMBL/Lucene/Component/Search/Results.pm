package EnsEMBL::Lucene::Component::Search::Results;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);

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
  my $species_name = $species eq 'all' ? 'all species' : $species;
  ( my $display_species = $species_name ) =~ s/_/ /;

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

      #         foreach my $group_name ( sort { $a cmp $b } keys %$results_by_group ) {
    foreach my $group_name ( 'Feature type', 'Species', 'Help' ) {

        #             my $url = '/'
        #               . $object->species
        #               . '/Search/Details?species='
        #               . $object->param('species')
        #               . ';idx=all;' . ';q='
        #               . $object->param('q');

      my $class = $group_classes[$i];

      my $group       = $results_by_group->{$group_name}->{results};
      my $group_total = delete $results_by_group->{$group_name}->{total};
      next if $group_total < 1;

      $html .= qq(<div class="$class">
<table class="search_results">
<tr><th colspan="2">By $group_name</th></tr>
<tr><td>Total</td><td>$group_total</td></tr>
      );

      foreach my $child_name ( sort { $a cmp $b } keys %{$group} ) {
        my $child = $group->{$child_name};
        $child_name =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
        $html .= qq(<tr>
                              <td>);

        my $child_name_no_underscore;
        ( $child_name_no_underscore = $child_name ) =~ s/_/ /g;

        $html .= qq(<a href="#" class="collapsible">$child_name_no_underscore</a><ul class="shut">\n);
        my $grandchild  = $child->{results};
        my $child_count = $child->{total};
        my $g_clipped;
        foreach my $g_name ( sort { $a cmp $b } keys %{$grandchild} ) {
          my $g_count = $grandchild->{$g_name}->{count};

            my $clipped = $grandchild->{$g_name}->{is_clipped_flag};
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
          # this needs fixed at source i.e. the Search Domain name
          $g_name =~ s/Help/Page Help/;
          $g_name =~ s/Docs/Documentation/;
          $g_name =~ s/Faq/FAQ/;

          $html .= qq#<li><a href="$g_url"> $g_name ($clipped$g_count)</a></li>#;
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
    warn "FOUND NOTHING";
    $html = $self->re_search;
  }
  return $html;
}

sub re_search {
  my $self   = shift;
  my $hub = $self->hub;

  my $html;

  my $species = $hub->param('species');
  my $species_name = $species eq 'all' ? 'all species' : $species;
  ( my $display_species = $species_name ) =~ s/_/ /;
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
    $html = qq(<h2>Your search of annotated features from $display_species for the term '$q' returned no results</h2>);
    my $url = '/' . $hub->species . '/Search/Results?species=all;idx=' . $hub->param('idx') . ';q=' . $q;
    $html .= sprintf qq(<h3>Would you like to search <a href="%s">the reset of the website</a> with this term ?</h3>), $url;
    return $html;
  }

  $html = qq(<h2>Your search of the Ensembl website for the term '$q' returned no results</h2>);
  $html .=
qq(<h3>If you are expecting to find features with this search term and think the failure to do so is an error, please <a href="/Help/Contact" class="popup">contact helpdesk</a> and let us know</h3>);
  return $html;
}

1;


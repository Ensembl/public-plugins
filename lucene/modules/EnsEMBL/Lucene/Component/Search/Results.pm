# $Id$

package EnsEMBL::Lucene::Component::Search::Results;

use strict;

use URI::Escape qw(uri_unescape);

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $sitetype         = $species_defs->ENSEMBL_SEARCHTYPE ? lc $species_defs->ENSEMBL_SEARCHTYPE : lc $species_defs->ENSEMBL_SITETYPE;
  my $species          = $hub->param('species');
  my $display_species  = $species eq 'all' ? sprintf('the %s website', ucfirst $sitetype) : $hub->species_defs->get_config($species,'SPECIES_COMMON_NAME');
  my $q                = uri_unescape($hub->param('q'));
  my $results_by_group = $self->object->groups;
  my $html;
 
  my @group_errors;
  my $any_ok = 0;
  if ($results_by_group->{'Species'}{'total'} && $results_by_group->{'Feature type'}{'total'} || $results_by_group->{'Help'}{'total'}) {
    $html = qq(<h3>Your search of $display_species with '$q' returned the following results:</h3>
      <div class="column-wrapper">);

    my @margin_fix_classes = (' no-left-margin', '', ' no-right-margin');

    foreach my $group_name ('Feature type', 'Species', 'Help') {
      my $group_total = delete $results_by_group->{$group_name}->{'total'};
      
      #return sprintf '<div><p class="space-below">Sorry, %s search is currently unavailable.</p></div>', ucfirst $sitetype if $group_total < 0;
      
      next if $group_total == 0;
      
      my $group        = $results_by_group->{$group_name}->{'results'};
      my $margin_class = shift @margin_fix_classes;
      my $total = qq(<tr><td>Total</td><td>$group_total</td></tr>);
      if($group_total < 0) {
        $total = '';
        push @group_errors,$group_name;
      }
      $html .= qq(
      <div class="column-three"><div class="column-padding$margin_class">
        <table class="search_results">
          <tr><th colspan="2">By $group_name</th></tr>
          $total
      );

      foreach my $child_name (sort { $group->{$a}{'sort_field'} cmp $group->{$b}{'sort_field'} } keys %{$group}) {
        my $child      = $group->{$child_name};
           $child_name =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
        my $display_n  = $child->{'sort_field'};
           $display_n  =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
           $display_n  =~  s/_/ /g;

        $html .= qq{
          <tr>
            <td>
              <a href="#" class="toggle closed">$display_n</a>
              <ul class="toggleable">
        };
        
        my $grandchild  = $child->{'results'};
        my $child_count = $child->{'total'};
        my $g_clipped;
        
        foreach my $g_name (sort { $grandchild->{$a}{'sort_field'} cmp $grandchild->{$b}{'sort_field'} } keys %{$grandchild}) {
          $any_ok = 1;
          my $gchild    = $grandchild->{$g_name};
          my $display_n = $gchild->{'sort_field'};
             $display_n =~ s/${sitetype}_(.*)$/ucfirst($1)/e;
          my $g_count   = $gchild->{'count'};
          my $clipped   = $gchild->{'is_clipped_flag'};
             $g_clipped = '>' if $clipped eq '>';
             $g_name    =~ s/${sitetype}_(.*)$/ucfirst($1)/e;

          # Handle Docs Urls differently
          my $g_url;
          
          if ($g_name =~ /faq|docs|glossary|help/i) {
            $g_url = $hub->url({'type' => 'Search', 'action' => 'Details', 'idx' => ucfirst($g_name), 'q' => $q, '__species' => 'all'});
          } else {
            my ($idx, $sp) = $group_name =~ /species/i ? ($g_name, $child_name) : ($child_name, $g_name);
            $sp     =~ s/\s/_/;
            $g_name =~ s/_/ /g;
            $g_url  = $hub->url({'species' => $sp, 'type' => 'Search', 'action' => 'Details', 'idx' => $idx, 'end' => $g_count, 'q' => $q, '__species' => $sp});
          }
          
          # yet more exceptions for Help and docs
          # change Help -> Page Help, Docs -> Documentation and Faq to FAQ
          # this should be fixed at source i.e. the Search Domain name
          $display_n =~ s/Help/Page Help/;
          $display_n =~ s/Docs/Documentation/;
          $display_n =~ s/Faq/FAQ/;
          $display_n =~ s/_/ /g;

          $html .= qq{<li><a href="$g_url"> $display_n ($clipped$g_count)</a></li>};
        }
        
        $html .= qq{
              </ul>
            </td>
            <td style="width:5em"><a href="#"> $g_clipped$child_count</a></td>
          </tr>
        };
      }

      $html .= qq{
        </table>
      </div></div>};
      
    }
    $html .= "\n</div>"; #close column-wrapper
    if(@group_errors) {
      if($any_ok) {
        my $beware = "Some search indices are not responding, search results may be missing or incomplete";
        $html = $self->_warning("Incomplete results","<p>$beware</p>").$html;
      } else {
        my $beware = "Sorry ".ucfirst($sitetype)." search is currently unavailable";
        $html = $self->_error("Search unavailable","<p>$beware</p>").$html;
      }
    }

  } else {
    $html = $self->re_search($q);
  }
  
  return $html;
}

sub re_search {
  my ($self, $q)      = @_;
  my $hub             = $self->hub;
  my $sitetype        = $hub->species_defs->ENSEMBL_SEARCHTYPE ? ucfirst lc $hub->species_defs->ENSEMBL_SEARCHTYPE : ucfirst lc $hub->species_defs->ENSEMBL_SITETYPE;
  my $species         = $hub->param('species');
  my $display_species = $species eq 'all' ? 'all species' : $hub->species_defs->get_config($species,'SPECIES_COMMON_NAME');
  my $html = qq(
        <div style="font-size:1.2em">
          <p class="space-below">Your search of <strong>$display_species</strong> with <strong>'$q'</strong> returned no results.</p>
            );
  
  if ($q =~ /^(\S+?)(\d+)/) {
    my $ens = $1;
    my $dig = $2;
    
    if ($ens =~ /ENS|OTT/ && length $dig != 11 && $ens !~ /ENSFM|ENSSNP/) {
      my $newq = $ens . sprintf "%011d", $dig;
      my $url  = $hub->url({'type' => 'Search', 'action' => 'Results', '__species' => $species, 'idx' => $hub->param('idx'), 'q' => $newq});
      
      $html .= qq{
          <p><strong>Would you like to <a href="$url">search using $newq</a> (note number of digits)?</strong></p>
      };
    }
  }
  elsif ($species ne 'all') {
    my $url = $hub->url({'type' => 'Search', 'action' => 'Results', '__species' => 'all', 'idx' => $hub->param('idx'), 'q' => $q});
    
    $html .= qq{
        <p><strong>Would you like to <a href="$url">search the rest of the website</a> with this term?</strong></p>
    };
  }
  else {
    $html = qq{
        <p><strong>If you are expecting to find features with this search term and think the failure to do so is an error, please <a href="/Help/Contact" class="popup">contact helpdesk</a> and let us know.</strong></p>
    };
  }

  $html .= '</div>';

  return $html;
 
}

1;


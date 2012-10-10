package EnsEMBL::Web::Component::Variation::LOVD;

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::Document::Table;
use EnsEMBL::Web::Tools::Misc;

use base qw(EnsEMBL::Web::Component::Variation);

sub _init {
    my $self = shift;
    $self->cacheable( 1 );
    $self->ajaxable(  1 );
}

sub caption {
    return undef;
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  my $lovd     = $hub->species_defs->LOVD_URL;
  return unless $lovd;

  ## Fetch LOVD data
  my $html;
  my $object   = $self->object;
  my %mappings = %{$object->variation_feature_mapping};
  my $column_set = []; 
  my $all_rows   = [];

  while (my ($key, $data) = each (%mappings)) {

    my $region   = $mappings{$key}{'Chr'};
    my $start    = $mappings{$key}{'start'};
    my $end      = $mappings{$key}{'end'};

    my $search = sprintf '%s?build=%s&position=chr%s:%s', 
                    $lovd, $hub->species_defs->UCSC_GOLDEN_PATH, $region, $start;
    $search .= '_'.$end if ($end != $start);

    my $response = get_url_content($search);
    if ($response->{'error'}) {
      warn ">>> ERROR ".$response->{'error'};
    }
    elsif ($response->{'content'}) {
      my ($columns, $rows) = $self->munge_content($response->{'content'});
      $column_set = $columns;
      push @$all_rows, @$rows;
    }
  }

  if (scalar @$all_rows) {        
    $html .= '<p>The following data is imported from LOVD (Leiden Open Variation Database):</p>';
    my $table = new EnsEMBL::Web::Document::Table($column_set, $all_rows, { data_table => 1, exportable => 0 });
    $html .= $table->render;    
  }
  else {
    $html .= '<p>No LOVD data was found for this variant</p>';
  }

  return $html;
}

sub munge_content {
  my ($self, $content) = @_;
  my $html;

  my $columns = [];
  my $col_keys = [];
  my $rows = [];
  my $i = 0;

  foreach my $row ( split /\n|\r/, $content ) {
    $row =~ s/^"//;
    $row =~ s/"$//;
    my @cols = split(/"(\s+)"/, $row);
    if ($i == 0) {
      $col_keys = \@cols;
      foreach (@cols) {
        my $header = $_;
        $header =~ s/_/ /;
        $header = 'More information' if $_ eq 'url';
        push @$columns, {'key' => $_, 'title' => $header};
      }
    }
    else {
      my $row = {}; 
      my $j = 0;
      foreach (@$col_keys) {
        my $data = $cols[$j];
        my $display;
        if ($_ eq 'url') {
          $display = sprintf '<a href="%s">Link</a>', $data; 
        }  
        elsif ($_ eq 'gene_id') {
          my $url = $self->hub->url({'type'=>'Gene','action'=>'Summary','g'=>$data});
          $display = sprintf '<a href="%s">%s</a>', $url, $data; 
        }
        else {
          $display = $data;
        }
        $row->{$_} = $display;
        $j++;
      }
      push @$rows, $row;
    }

    $i++;
  }

  return ($columns, $rows);

}


1;


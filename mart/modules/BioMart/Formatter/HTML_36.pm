#
# BioMart module for BioMart::Formatter::HTML_36

# POD documentation - main docs before the code.

=head1 NAME

BioMart::Formatter::HTML_36

=head1 SYNOPSIS

The HTML_36 Formatter returns data formatted into a HTML_36 table
for a BioMart query's ResultTable

=head1 DESCRIPTION

When given a BioMart::ResultTable containing the results of 
a BioMart::Query the HTML_36 Formatter will return HTML_36 formatted tabular 
output. The getDisplayNames and getFooterText can be used to return 
appropiately formatted headers and footers respectively. If hyperlink
templates are defined for the attributes in the Dataset's ConfigurationTree
then appropiate hyperlinks will be calculated for each cell of the table.
Addition of any extra attributes to the Query that may be required for this
hyperlink formatting is handled in this Formatter

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

=head1 AUTHORS

=over

=item *
Damian Smedley

=item *
Gudmundur Thorisson

=back

=head1 CONTACT

This module is part of the BioMart project
http://www.biomart.org

Questions can be posted to the mart-dev mailing list:
mart-dev@ebi.ac.uk

=head1 METHODS

=cut

package BioMart::Formatter::HTML_36;

use strict;
use warnings;
use Readonly;

use BioMart::Web::SpeciesDefs;
use EnsEMBL::Web::DBSQL::DBConnection;

eval{
require Bio::EnsEMBL::SimpleFeature;
require Bio::EnsEMBL::Analysis;
require Bio::EnsEMBL::DBSQL::DBAdaptor;
};
# Constants

Readonly  my $current_assembly => 'NCBIM37';
Readonly  my $new_assembly => 'NCBIM36';
Readonly my $host => '127.0.0.1';
Readonly my $port => '3309';
Readonly my $user => '????';
Readonly my $pass => '????';
Readonly my $dbname => 'mus_musculus_core_47_37';


# Extends BioMart::FormatterI
use base qw(BioMart::FormatterI);

# HTML templates
my $current_rowcount = 0; # keep track of number of rows printed out
Readonly my $FOOTER_TMPL => qq{</div>

</body>
</html>
};
Readonly my $HEADER_TMPL => q{<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title>%s</title>
  <link rel="stylesheet" type="text/css" href="/martview/martview.css" />
</head>
<body>

<table>
};
Readonly my $ROW_START_TMPL1 => qq{<tr>\n};
Readonly my $ROW_START_TMPL2 => qq{<tr>\n};
Readonly my $HEADERFIELD_TMPL1     => qq{  <th>%s</th>\n};
Readonly my $HEADERFIELD_TMPL2    => qq{  <th>%s</th>\n};
Readonly my $NORMALFIELD_TMPL1     => qq{  <td>%s</td>\n};
Readonly my $ROW_END_TMPL   => qq{</tr>\n};


sub _new {
    my ($self) = @_;
    $self->SUPER::_new();

    # connect to database and get adaptors
    my $db = EnsEMBL::Web::DBSQL::DBConnection->new( 'Mus_musculus', BioMart::Web::SpeciesDefs->species_defs
      )->get_DBAdaptor( 'core', 'Mus_musculus' );
    $self->attr('db_adaptor',$db);
}

sub getFormatterDisplayName {
    return 'Mouse 36 assembly (HTML)';
}


sub processQuery {
    my ($self, $query) = @_;
    $self->set('original_attributes',[@{$query->getAllAttributes()}]) 
	if ($query->getAllAttributes());
    $query = $self->setHTMLAttributes($query);
    $query->addAttribute('strand');
    $query->addAttribute('chromosome_name');
    $self->set('query',$query);
    return $query;
}

sub nextRow {
   my $self = shift;

   my $rtable = $self->get('result_table');

   # print the data with urls if available
   my $new_row;
   my $row = $rtable->nextRow;
   if (!$row){
       return;
   }





   my $chromosome = $$row[-1];
   my $strand = $$row[-2];

   # convert coordinates to NCBI36 assembly
   my @atts_to_convert = qw(
                             start_position
                             end_position
                             transcript_start
                             transcript_end
                             feat_chr_start
                             feat_chr_end
                             gene_chrom_start
                             gene_chrom_end
                             transcript_chrom_start
                             transcript_chrom_end
                             exon_chrom_start
                             exon_coding_end
                             exon_chrom_end
                             exon_coding_start
                             chromosome_location
                             );
   my $attribute_order = $self->get('original_attributes');
   my $attribute_number = 0;
   my ($orig_attribute,$position,$new_position);
   foreach (@$attribute_order){
       $orig_attribute = $_->name;
       foreach (@atts_to_convert){
	   if ($orig_attribute eq $_){
                # covert coordinates
	       $position = $$row[$attribute_number];
	       
	       next if (!$position);
	       my $db = $self->get('db_adaptor');
	       my $sa = $db->get_SliceAdaptor();

               # create an analysis for the type of feature you wish to store
                my $analysis = Bio::EnsEMBL::Analysis->new(
                                                          -LOGIC_NAME => 'your_analysis'
                                                          );
                my $slice_oldasm = $sa->fetch_by_region('chromosome', $chromosome, undef, undef,
                                                        undef, $current_assembly);



                # create a new feature on the old assembly
                my $feat = Bio::EnsEMBL::SimpleFeature->new(
                                                            -DISPLAY_LABEL  => '',
                                                            -START          => $position,
                                                            -END            => $position,
                                                            -STRAND         => $strand,
                                                            -SLICE          => $slice_oldasm,
                                                            -ANALYSIS       => $analysis,
							    );

                # project feature to new assembly
	       my $feat_slice = $feat->feature_Slice;
	       my @segments;
	       if ($feat_slice){
		   @segments = @{ $feat->feature_Slice->project('chromosome', $new_assembly) };
	       }


                # do some sanity checks on the projection results:
                # discard the projected feature if
                #   1. it doesn't project at all (no segments returned)
                #   2. the projection is fragmented (more than one segment)
                #   3. the projection doesn't have the same length as the original
                #      feature

	       if (scalar(@segments) != 1){
		   $new_position = '-';
	       }
	       elsif ($segments[0]->to_Slice()->length != $feat->length){
		   $new_position = '-';
	       }
	       elsif ($segments[0]->to_Slice()->seq_region_name ne $feat->slice->seq_region_name){
		   $new_position = '-';
	       }
	       else{
		   $new_position = $segments[0]->to_Slice()->start;
	       }

	       $$row[$attribute_number] = $new_position;
	   }
       }
       $attribute_number++;
   }
   my $new_row_length = @$row - 3;
   $row = [@$row[0..$new_row_length]];


   


   map { $_ = q{} unless defined ($_); } @$row;
   my $attribute_positions = $self->get('attribute_positions');
   my $attribute_url_positions = $self->get('attribute_url_positions');
   my $attribute_url = $self->get('attribute_url');

   #my $dataset1_end = $self->get('dataset1_end');

   for (my $i = 0; $i < @{$attribute_positions}; $i++){
       # superscripting for emma mart
       $$row[$$attribute_positions[$i]] =~ s/\<(.*)\>/<span style="vertical-align:super;font-size:0.8em">$1<\/span>/;
	   


       if ($$attribute_url[$i]){
	   my @url_data = map {$$row[$_]} @{$$attribute_url_positions[$i]};
	   my $url_string = sprintf($$attribute_url[$i],@url_data);
	   push @{$new_row}, '<a href="'.$url_string.'" target="_blank">'.
	       $$row[$$attribute_positions[$i]]."</a>";
       }
       else{
	   push @{$new_row},$$row[$$attribute_positions[$i]];
       }
   }

   $current_rowcount++;
   my $fields_string = '';
   map{ $fields_string .= sprintf ($NORMALFIELD_TMPL1, defined ($_) ? $_ : ''); } @{$new_row};
   return ($current_rowcount % 2 == 0 ? $ROW_START_TMPL1 : $ROW_START_TMPL2)
	                              . $fields_string
                                      . $ROW_END_TMPL;
}

sub getDisplayNames {
    my $self = shift;

    my $original_attributes = $self->get('original_attributes');
    my $dataset1_end = $self->get('dataset1_end');
    my $query = $self->get('query');
    my $registry = $query->getRegistry;
    my $final_dataset_order = $query->finalDatasetOrder;
    
    my @attribute_display_names;
    my @original_dataset_attributes;
    foreach my $dataset(reverse @$final_dataset_order){
	foreach (@{$original_attributes}){
	    push @original_dataset_attributes,$_ 
		if ($_->dataSetName eq $dataset);
	}
    }
    foreach my $original_attribute(@original_dataset_attributes){
	push @attribute_display_names, $original_attribute->displayName;
    }

    # print the display names    
    my $header_string = sprintf $HEADER_TMPL, '';
    $header_string .= $ROW_START_TMPL1;
#    map{ $header_string .= 
#	     sprintf $HEADERFIELD_TMPL, $_ } @attribute_display_names;
    map{ $header_string .= sprintf $HEADERFIELD_TMPL1, $_ } @attribute_display_names[0..$dataset1_end];
    map{ $header_string .= sprintf $HEADERFIELD_TMPL2, $_ } @attribute_display_names[$dataset1_end+1..@attribute_display_names-1];
    $header_string .= $ROW_END_TMPL;
    return $header_string;
}

# Override empty-string returning method in superclass, to return proper 
# table- and document-closing tags (to keep HTML valid).
sub getFooterText {   
    return q{
</table>
</body>
</html>
};
}

sub getMimeType {
    return 'text/html';
}


1;

#
# BioMart module for BioMart::Formatter::CSV_36

# POD documentation - main docs before the code.

=head1 NAME

BioMart::Formatter::CSV_36

=head1 SYNOPSIS

The CSV_36 Formatter returns tab separated tabular data
for a BioMart query's ResultTable

=head1 DESCRIPTION

When given a BioMart::ResultTable containing the results of 
a BioMart::Query the CSV_36 Formatter will return tabular output
with one line for each row of data in the ResultTable and tabs
separating the individual entries in each row. The getDisplayNames
and getFooterText can be used to return appropiately formatted
headers and footers respectively

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

=back

=head1 CONTACT

This module is part of the BioMart project
http://www.biomart.org

Questions can be posted to the mart-dev mailing list:
mart-dev@ebi.ac.uk

=head1 METHODS

=cut

package BioMart::Formatter::CSV_36;

use strict;
use warnings;

# Extends BioMart::FormatterI
use base qw(BioMart::FormatterI);
use Readonly;
use Getopt::Long;
use BioMart::Web::SpeciesDefs;
use EnsEMBL::Web::DBSQL::DBConnection;
eval{
require Bio::EnsEMBL::SimpleFeature;
require Bio::EnsEMBL::Analysis;
require Bio::EnsEMBL::DBSQL::DBAdaptor;
};
# Constants

Readonly my $FIELD_DELIMITER  =>  q{,};
Readonly my $RECORD_DELIMITER => qq{\n};
Readonly my $FIELD_ENCLOSER   => qq{\"};

Readonly  my $current_assembly => 'NCBIM37';
Readonly  my $new_assembly => 'NCBIM36';
Readonly my $host => '127.0.0.1';
Readonly my $port => '3309';
Readonly my $user => '????';
Readonly my $pass => '????';
Readonly my $dbname => 'mus_musculus_core_47_37';

sub _new {
    my ($self) = @_;
    $self->SUPER::_new();

    # connect to database and get adaptors
    my $db = EnsEMBL::Web::DBSQL::DBConnection->new( 'Mus_musculus', BioMart::Web::SpeciesDefs->species_defs
      )->get_DBAdaptor( 'core', 'Mus_musculus' );
    $self->attr('db_adaptor',$db);
}

sub getFormatterDisplayName {
    return 'Mouse 36 assembly (CSV)';
}


sub processQuery {
    my ($self, $query) = @_;

    $self->set('original_attributes',[@{$query->getAllAttributes()}]) 
	if ($query->getAllAttributes());
    $query->addAttribute('strand');
    $query->addAttribute('chromosome_name');
    $self->set('query',$query);
    return $query;
}

sub nextRow {
    my $self = shift;

    my $rtable = $self->get('result_table');
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



    # Enclose non-numeric values in double quotes & escape the quotes already in them
    foreach(@{$row}) {
        $_ = q{} unless defined ($_);
        if($_ !~ /\A[\d\.]+\z/ && $_ =~ /$FIELD_DELIMITER/) {
            $_ =~ s/$FIELD_ENCLOSER/\$FIELD_ENCLOSER/g;
            $_ = $FIELD_ENCLOSER . $_ . $FIELD_ENCLOSER;
        }
    }
    
    # Create the final record-string
    return join($FIELD_DELIMITER, @{$row}) . $RECORD_DELIMITER;


}

sub getDisplayNames {
    my $self = shift;
    my @displayNames = $self->getTextDisplayNames();


    # Enclose non-numeric values in double quotes & escape the quotes already in them
    foreach(@displayNames) {
        if($_ !~ /\A[\d\.]+\z/ && $_ =~ /$FIELD_DELIMITER/) {
            $_ =~ s/$FIELD_ENCLOSER/\$FIELD_ENCLOSER/g;
            $_ = $FIELD_ENCLOSER . $_ . $FIELD_ENCLOSER;
        }
    }

    # Create the final header string
    return join($FIELD_DELIMITER, @displayNames) . $RECORD_DELIMITER;


}

1;




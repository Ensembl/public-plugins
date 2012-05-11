# $Id$
package EnsEMBL::Selenium::Test::FTPtable;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# NOTE: THIS NEEDS TO BE RUN ON LIVE ONLY
# Ensembl FTP Table link
# Testing all the ftp link on the documentation page. 
#------------------------------------------------------------------------------

sub test_ftptable {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $location = $self->get_location();
    
  $sel->open_ok('info/data/ftp/index.html')
  and $sel->ensembl_wait_for_page_to_load;
  
  $sel->ensembl_click_all_links('#ftp-table1');     #click through all the links on the top FTP table (Multi species data)
  $sel->ensembl_click_all_links('#ftp-table');      # and for the FTP table Single species data
}
1;
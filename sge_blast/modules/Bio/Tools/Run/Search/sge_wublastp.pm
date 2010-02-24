
=head1 NAME

Bio::Tools::Run::Search::sge_wublastp - SGE BLASTP searches

=head1 SYNOPSIS

  see Bio::Tools::Run::Search::SGE_WuBlast
  see Bio::Tools::Run::Search::wublastp

=head1 DESCRIPTION

Multiple inheretance object combining
Bio::Tools::Run::Search::SGE_WuBlast and
Bio::Tools::Run::Search::wublastp

=cut

# Let the code begin...
package Bio::Tools::Run::Search::sge_wublastp;
use strict;

use vars qw( @ISA );

use Bio::Tools::Run::Search::SGE_WuBlast;
use Bio::Tools::Run::Search::wublastp;

@ISA = qw( Bio::Tools::Run::Search::SGE_WuBlast 
           Bio::Tools::Run::Search::wublastp );

BEGIN{
}

# Nastyness to get round multiple inheretance problems.
sub program_name{return Bio::Tools::Run::Search::wublastp::program_name(@_)}
sub algorithm   {return Bio::Tools::Run::Search::wublastp::algorithm(@_)}
sub version     {return Bio::Tools::Run::Search::wublastp::version(@_)}
sub parameter_options{
  return Bio::Tools::Run::Search::wublastp::parameter_options(@_)
}

#----------------------------------------------------------------------
1;


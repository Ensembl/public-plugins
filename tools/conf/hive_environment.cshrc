#config for tools
setenv ENS_CODE_ROOT /nfs/users/nfs_w/www-ens/blast_test
setenv ENSEMBL_CVS_ROOT_DIR $ENS_CODE_ROOT
alias beekeeper 'beekeeper.pl -url mysql://ensadmin:ensembl@ensdb-web-15:5307/ensembl_web_hive -run -keep_alive'
set path = ( $ENS_CODE_ROOT/ensembl-hive/scripts $path )

setenv PERL5LIB $ENS_CODE_ROOT/ensembl/modules:$ENS_CODE_ROOT/ensembl-hive/modules:$ENS_CODE_ROOT/conf:$ENS_CODE_ROOT/ensembl-external/modules:$ENS_CODE_ROOT/modules:$ENS_CODE_ROOT/sanger-plugins/tools/modules:/localsw/cvs/bioperl-live:$PERL5LIB

#setenv PERL_LOCAL_LIB_ROOT "$PERL_LOCAL_LIB_ROOT:/data_ensembl/blastdb/blast_test"
setenv PERL_LOCAL_LIB_ROOT "/data_ensembl/blastdb/blast_test"
setenv PERL_MB_OPT "--install_base /data_ensembl/blastdb/blast_test"
setenv PERL_MM_OPT "INSTALL_BASE=/data_ensembl/blastdb/blast_test"
setenv PERL5LIB "/data_ensembl/blastdb/blast_test/lib/perl5:$PERL5LIB"
setenv PATH "/data_ensembl/blastdb/blast_test/bin:$PATH"

package BioMart::Web::PageStub;
use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Document::Renderer::Apache;
use EnsEMBL::Web::Document::Dynamic;
use EnsEMBL::Web::Document::Static;
use CGI::Session;
use CGI::Session::Driver::mysql; # required by CGI::Session
use CGI qw(self_url);
use Exporter;
use Data::Dumper;
our @EXPORT = qw(generate_biomart_session);
our @EXPORT_OK = qw(generate_biomart_session);
our %EXPORT_TAGS = ('ALL'=>[qw(generate_biomart_session)]);
our @ISA = qw(Exporter);

sub generate_biomart_session {
  my( $biomart_web_obj, $session_id ) = @_;
  CGI::Session->find( sub {} );
  my $T = CGI::Session->new('driver:mysql', $session_id, {
    'Handle' => $ENSEMBL_WEB_REGISTRY->dbAdaptor->get_dbhandle
  });
  return $T;
}

sub new {
  my( $class, $session ) = @_;
warn "INIT WEB MODULE...";
  my $renderer = new EnsEMBL::Web::Document::Renderer::Apache;
  my $page     = new EnsEMBL::Web::Document::Dynamic( $renderer,undef,$ENSEMBL_WEB_REGISTRY->species_defs );
  $page->_initialize_HTML;
  $page->set_doc_type( 'none', 'none' );
  $page->masthead->sp_bio    ||= 'BioMart';
  $page->masthead->sp_common ||= 'BioMart';
  $page->javascript->add_source( '/biomart/mview/js/martview.js' );
#  $page->javascript->add_script( 'addLoadEvent( debug_window )' );
  $page->javascript->add_script( 'addLoadEvent( setVisibleStatus )' );
  $page->stylesheet->add_sheet(  'all', '/biomart/mview/martview.css'      );

  my $self = {
    'page'    => $page,
    'session' => $session,
    'ajax'    => CGI::self_url() =~ m/__.+ByAjax/ ? 1 : 0
  };
  bless $self, $class;
  return $self;
}


sub start {
  my $self = shift;
  return if $self->{'ajax'};
  $self->{'page'}->render_start;
#  print '<script type="text/javascript">debug_window()</script>';
  $self->{'page'}->content->_start;
  $self->{'page'}->content->render_settings_list;
}

sub end {
  my $self = shift;
  return if $self->{'ajax'};
  $self->{'page'}->content->_end;
  if($self->{'session'}->param('__validatorError')) {
    ( my $inc = $self->{'session'}->param("__validationError") ) =~ s/\n/\\n/;
    $inc =~s/\'/\\\'/;
    print qq(<script language="JavaScript" type="text/javascript">
  //<![CDATA[
  alert('$inc');
  //]]>
  </script>);
  }
  $self->{'page'}->render_end;
}

1;

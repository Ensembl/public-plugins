package BioMart::Web::PageStub;

use strict;

use CGI qw(self_url);
use CGI::Session;
use CGI::Session::Driver::mysql; # required by CGI::Session

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Controller;


our @EXPORT      = qw(generate_biomart_session);
our @EXPORT_OK   = qw(generate_biomart_session);
our %EXPORT_TAGS = ('ALL' => [ 'generate_biomart_session' ]);

use base qw(Exporter);

sub new {
  my ($class, $session) = @_;
  my $self = {};
  
  if (CGI::self_url !~ /__.+ByAjax/) {
    my $controller = EnsEMBL::Web::Controller->new(undef, { page_type => 'Static', renderer_type => 'Apache' });
    my $page       = $controller->page;    

    $page->include_navigation(0);
    $page->initialize;
    $page->remove_body_element('breadcrumbs');
    $page->set_doc_type('none', 'none');
    
    my $elements = $page->elements;
    my @order    = map $_->[0], @{$page->head_order}, @{$page->body_order};
    my $content;
    
    foreach my $element (@order) {
      my $html_module = $elements->{$element};
      $html_module->init($controller) if $html_module->can('init');
    }
   
    $page->javascript->add_source('/biomart/mview/js/martview.js');
    $page->body_javascript->add_script('addLoadEvent(setVisibleStatus)');
    $page->stylesheet->add_sheet('all', '/biomart/mview/martview.css');
    $page->stylesheet->add_sheet('all', '/martview-hacks.css');
 
    foreach my $element (@order) {
      my $html_module = $elements->{$element};
      $content->{$element} = $html_module->content;
    }
    
    $self = {
      page     => $page,
      session  => $session,
      content  => $content,
      not_ajax => 1
    };
  }
  
  bless $self, $class;
  return $self;
}

sub generate_biomart_session {
  my ($biomart_web_obj, $session_id) = @_;
  
  CGI::Session->find(sub {});
  
  return CGI::Session->new('driver:mysql', $session_id, {
    Handle => $ENSEMBL_WEB_REGISTRY->user_db_handler
  });
}

sub start {
  my $self = shift;
  
  return unless $self->{'not_ajax'};
  
  $self->render_start;
}

sub end {
  my $self = shift;
  
  return unless $self->{'not_ajax'};
  
  if ($self->{'session'}->param('__validatorError')) {
    (my $inc = $self->{'session'}->param('__validationError')) =~ s/\n/\\n/;
    $inc     =~ s/\'/\\\'/;
    
    print qq{
      <script type="text/javascript">
        //<![CDATA[
        alert('$inc');
        //]]>
      </script>
    };
  }
  
  $self->render_end;
}

sub render_start {
  my $self = shift;
  my $page = $self->{'page'};
  
  $page->add_body_attr('id',    'ensembl-webpage');
  $page->add_body_attr('class', 'mac')                               if $ENV{'HTTP_USER_AGENT'} =~ /Macintosh/;
  $page->add_body_attr('class', "ie ie$1" . ($1 < 8 ? ' ie67' : '')) if $ENV{'HTTP_USER_AGENT'} =~ /MSIE (\d+)/ && $1 <  9;
  $page->add_body_attr('class', "ienew ie$1")                        if $ENV{'HTTP_USER_AGENT'} =~ /MSIE (\d+)/ && $1 >= 9;
  $page->add_body_attr('class', 'no_tabs');
  $page->add_body_attr('class', 'static');

  my $content    = $self->{'content'};
  my $html_tag   = join '', $page->doc_type, $page->html_tag;
  my $head       = join "\n", map $content->{$_->[0]} || (), @{$page->head_order};   
  my $body_attrs = join ' ', map { sprintf '%s="%s"', $_, $page->{'body_attr'}{$_} } grep $page->{'body_attr'}{$_}, keys %{$page->{'body_attr'}};
  
  print qq{$html_tag
<head>
  $head
</head>
<body $body_attrs>
  <div id="min_width_container">
    <div id="min_width_holder">
      <div id="masthead" class="js_panel">
        <input type="hidden" class="panel_type" value="Masthead" />
        <div class="logo_holder">$content->{'logo'}</div>
        <div class="mh print_hide">
          <div class="account_holder">$content->{'account'}</div>
          <div class="tools_holder">$content->{'tools'}</div>
          <div class="search_holder print_hide">$content->{'search_box'}</div>
        </div>
      </div>
      <div id="main_holder"> 
        <div id="main">
  };
}


sub render_end {
  my $self     = shift;
  my $content = $self->{'content'};
  
  print qq{
        </div>
        <div id="wide-footer">
          <div style="font-size:150%;font-weight:bold">
            <p>Datasets -&gt; Filters (filtering and inputs) -&gt; Attributes (desired output) -&gt; Results</p>
            <p>Biomart tutorial: <a href="http://youtu.be/DXPaBdPM2vs">YouTube</a> | <a href="http://v.youku.com/v_show/id_XMjQ2MjkwMTg0.html">YouKu</a></p>
          </div>
          $content->{'copyright'}
          $content->{'footerlinks'}
        </div>
      </div>
    </div>
  </div>
  $content->{'modal'}
  $content->{'body_javascript'}
</body>
</html>
};
}

1;

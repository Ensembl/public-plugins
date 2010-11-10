package EnsEMBL::Web::Document::Element::BodyJavascript;

use strict;

sub content {
  my $self    = shift;
  my $content = qq{
    $self->{'scripts'}
    <script type="text/javascript" src="/tiny_mce/jscripts/tiny_mce/jquery.tinymce.js"></script>
    <div id="uploadframe_div" style="display: none"><iframe name="uploadframe"></iframe></div>
  };
  
  $content .= '<div id="debug"></div>' if $self->debug;
  
  return $content;
} 

1;

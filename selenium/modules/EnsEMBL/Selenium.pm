# $Id$
package EnsEMBL::Selenium;
use strict;
use Test::More;
use base 'Test::WWW::Selenium';

# return user defined timeout, or a default
sub _timeout {  return $_[0]->{_timeout} || 50000 }

# Wait until there are no ajax loading indicators or errors shown in the page
# Loading indicators are only shown if loading takes >500ms so need to pause before we start checking
#TODO::: Make ajax check when there are multiple ajax request see Selenium.pm.bk and 98_selenium.js
sub ensembl_wait_for_ajax {
  my ($self, $timeout, $pause) = @_;
  my $url = $self->get_location();
  
  $pause   ||= 500;   
  #increase the pause and timeout if we are testing mirrors since the site is slower.
  $pause += 3000 if($url =~ /uswest|useast|ec2/);  
  $timeout += 20000 if($url =~ /uswest|useast|ec2/);
  $self->pause($pause); 
  
  #print "\nAJAX ERROR: $url !!! \n"  unless 
  $self->wait_for_condition(
    qq/var \$ = selenium.browserbot.getCurrentWindow().jQuery;
    !(\$(".ajax_load").length || \$(".ajax_error").length || \$(".syntax-error").length)/,
    $timeout || $self->_timeout
  );  
  #$("#modal_panel .modal_content:visible .syntax-error").length
}

# Wait for a 200 Ok response, then wait until all ajax loaded
# For some reason the Ensembl 'Internal Server Error' page is mistaken for a 200 Ok, so also check for this
sub ensembl_wait_for_page_to_load {
  my ($self, $timeout) = @_;
  
#  my $url = $self->get_location();
  $timeout ||= $self->_timeout;
#  $timeout += 20000 if($url =~ /uswest|useast|ec2/);
  
  $self->wait_for_page_to_load_ok($timeout)
  and ok($self->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error')
  and $self->ensembl_wait_for_ajax_ok('50000');
}

# Open a ZMenu by title for the given imagemap panel or if title not provided will get the coords based on the area tag for the given imagemap panel (id of div for class js_panel)
# e.g. $sel->ensembl_open_zmenu('contigviewtop', 'ASN2') or $sel->ensembl_open_zmenu('GenomePanel')
# params: $panel      - the id of the view panel for the ZMenu to be tested
#         $aread_tag  - Anything within the area tag to be tested so that we can get the coords for the ZMenu. can be href or a class or title.
#         $track_name - Just the name of the track for the ZMenu to be tested, used for display information only in the log.
 
sub ensembl_open_zmenu {
  my ($self, $panel, $area_tag, $track_name) = @_;
  my $tag = $area_tag ?  "area[$area_tag]" : 'area[href^=#vdrag]';  

# $('area[class^="group"]','#RegulationImage').attr('coords').split(',')
# Ensembl.PanelManager.panels.RegulationImage.makeZMenu({pageX:0, pageY:0}, {x:1763, y:148});

  print "  Test ZMenu $track_name on the $panel panel \n";
  $self->run_script(qq/
    var coords = \$('$tag', '#$panel').attr('coords').split(',');
    Ensembl.PanelManager.panels.$panel.makeZMenu({pageX:0, pageY:0}, {x:coords[0], y:coords[1]});
  /)
  and $self->ensembl_wait_for_ajax(undef,'7000');
}

# Open a ZMenu by position on the given imagemap panel
# e.g. $sel->ensembl_open_zmenu_at('contigviewtop', '160,100')
sub ensembl_open_zmenu_at {
  my ($self, $panel, $pos) = @_;
  
  my ($x, $y) = split /,/, $pos;
  $self->run_script("Ensembl.PanelManager.panels['$panel'].makeZMenu({pageX:0, pageY:0}, {x:$x, y:$y});")
  and $self->ensembl_wait_for_ajax(undef,'7000');
}

# Overloading click_ok function so that it returns the current url when it fails, only used this function when ensembl_click_links below does not work like an ajax button
sub ensembl_click {
  my ($self, $link, $timeout) = @_;
  my $url = $self->get_location();
    
  print "URL:: $url \n\n" unless $self->click_ok($link,$timeout);
}

# Click links on ensembl but can only be used for link opening page, not ajax popup
# e.g. $sel->ensembl_click_links(["link=Tool","link=Human"], '5000');
sub ensembl_click_links {
  my ($self, $links, $timeout) = @_;
  my $location = $self->get_location();  
  
  if (ref $links eq 'ARRAY') {
    foreach my $link (@{$links}) {
      my ($locator, $timeout) = ref $link eq 'ARRAY' ? @$link : ($link, $timeout || $self->_timeout);
      if ($self->is_element_present($locator)) {
        print "$locator FAILED in $location \n\n" unless $self->click_ok($locator) and $self->ensembl_wait_for_page_to_load($timeout);
      } else {        
        print "***missing*** $locator in $location \n";
      }
    }
  }
}

# finding all links within an element and clicking each of them
# params: $div - The id or class for the container of the links
#         @skip_link - array of links you want to skip such as home 
#         $text - text to look for on the pages from the link
sub ensembl_click_all_links {
  my ($self, $div, $skip_link, $text) = @_;  
  my $location = $self->get_location();

  # get all the links on the page
  my $links_href = $self->get_eval(qq{
    var \$ = selenium.browserbot.getCurrentWindow().jQuery;
    \$('$div').find('a');
  });
    
  my @links_array = split(',',$links_href);
  my $i = 0;
  foreach my $link (@links_array) {    
    # get the text for each link, use link_text to click link if there is no id to the links
    my $link_text = $self->get_eval(qq{
      \var \$ = selenium.browserbot.getCurrentWindow().jQuery; 
      \$('$div').find('a:eq($i)').text();
    });
    
    # get id for the links
    my $link_id = $self->get_eval(qq{
      \var \$ = selenium.browserbot.getCurrentWindow().jQuery; 
      \$('$div').find('a:eq($i)').attr('id');
    });    
    
    #see if link is external
    my $rel = $self->get_eval(qq{
      \var \$ = selenium.browserbot.getCurrentWindow().jQuery; 
      \$('$div').find('a:eq($i)').attr('rel');
    });
    
    $i++;
    next if grep (/$link_text/, @$skip_link);
    
    if($rel eq 'external') {
      $self->open_ok($link);
      print "LINK FAILED:: $link_text($link) at $location \n\n" unless ok($self->get_title !~ /Internal Server Error|404 error|ERROR/i, 'No Internal or 404 Server Error');
    } else {
      $link_id && $link_id ne 'null' ? $self->ensembl_click_links(["id=$link_id"]) : $self->ensembl_click_links(["link=$link_text"]);
    }
    
    $self->ensembl_is_text_present($text) if($text);
    $self->go_back();
  }
}

# check if all the images (ajax one) on the page have been loaded successfully
sub ensembl_images_loaded {
  my ($self) = @_;
       
#jQuery('img.imagemap')[0].complete  
  $self->run_script(qq{
    var complete = 0;
     jQuery('img.imagemap').each(function () {
       if (this.complete) {
         complete++;
       }
     });
     if (complete === jQuery('img.imagemap').length) {
       jQuery('body').append("<p>All images loaded successfully</p>");
     }
  });
  my $location = $self->get_location();
  $self->ensembl_is_text_present("All images loaded successfully");
}


#Overloading is_text_present function so that it returns the current url when it fails
sub ensembl_is_text_present {
  my ($self, $text) = @_;
  my $url = $self->get_location();
    
  print "URL:: $url \n\n" unless $self->is_text_present_ok($text);
}

sub ensembl_has_das_error {
  my $self = shift;
  return $self->is_element_present("//div[\@id='TextDAS']//div[\@class='error-pad']");
}

#overloading select to return URL where the action fails.
sub ensembl_select {
  my ($self, $select_locator, $option_locator) = @_;
  my $url = $self->get_location();
    
  print "URL:: $url \n\n" unless $self->select_ok($select_locator,$option_locator);  
}


1;

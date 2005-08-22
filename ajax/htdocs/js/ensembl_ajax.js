function load_image_into( species, panel_name, pars ) {
  tempAJAX = new AJAXRequest( 'GET', '/'+species+'/location_image'+pars, '', loadImageCallBack, panel_name );
}

function loadImageCallBack( myAJAX, panel_name ) {
  if( myAJAX.readyState == 4 ) {
    resp = myAJAX.responseText;
    if( document.getElementById(panel_name) ) {
      document.getElementById(panel_name).innerHTML = resp;
    }
  }
}

function ajaxCheck( ID ) {
  tempAJAX = new AJAXRequest( 'GET', '/perl/imgtest?i='+ID+';t=ajax', '', ajaxCheckCallBack );
} 

function ajaxCheckCallBack( myAJAX ) {
  if( myAJAX.readyState == 4 ) {
    resp = myAJAX.responseText;
    if( document.getElementById('ajax') ) {
      document.getElementById('ajax').innerHTML = resp;
    }
  }
}

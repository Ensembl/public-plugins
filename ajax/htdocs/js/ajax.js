function encode( uri ) {
 if( escape             ) return escape(uri);
 if( encodeURIComponent ) return encodeURIComponent(uri);
}

function decode( uri ) {
  uri = uri.replace(/\+/g, ' ');
  if( decodeURIComponent ) return decodeURIComponent(uri);
  if( unescape           ) return unescape(uri);
  return uri;
}

function executeReturn( AJAX ) {
  if( AJAX.readyState == 4 ) {
    if( AJAX.status == 200 ) {
      eval(AJAX.responseText);
    }
  }
}

var _ms_XMLHttpRequest_ActiveX = "";

function AJAXRequest( method, url, data, process, extra, async, dosend ) {
  // self = this; creates a pointer to the current function
  // the pointer will be used to create a "closure". A closure
  // allows a subordinate function to contain an object reference to the
  // calling function. We can't just use "this" because in our anonymous
  // function later, "this" will refer to the object that calls the function
  // during runtime, not the AJAXRequest function that is declaring the function
  // clear as mud, right?
  // Java this ain't

  var self = this;

  // check the dom to see if this is IE or not
  if( window.XMLHttpRequest ) { // Not IE
    self.AJAX = new XMLHttpRequest();
  } else if( window.ActiveXObject ) { // Hello IE! --
    if( _ms_XMLHttpRequest_ActiveX ) { // Instantiate the latest MS ActiveX Objects
      self.AJAX = new ActiveXObject( _ms_XMLHttpRequest_ActiveX );
    } else { // loops through the various versions of XMLHTTP to ensure we're using the latest
      var versions = [ "Msxml2.XMLHTTP.7.0", "Msxml2.XMLHTTP.6.0",
                       "Msxml2.XMLHTTP.5.0", "Msxml2.XMLHTTP.4.0",
                       "MSXML2.XMLHTTP.3.0", "MSXML2.XMLHTTP",
                       "Microsoft.XMLHTTP" ];
      for (var i = 0; i < versions.length ; i++) {
        try { // try to create the object
                          // if it doesn't work, we'll try again
                          // if it does work, we'll save a reference to the proper one to speed up future instantiations
          self.AJAX = new ActiveXObject(versions[i]);
          if( self.AJAX ) {
            _ms_XMLHttpRequest_ActiveX = versions[i];
            break;
          }
        }
        catch (objException) { // trap; try next one
        };
      };
    }
  }

  // if no callback process is specified, then assing a default which executes the code returned by the server
  if( typeof process == 'undefined' || process == null ) {
    process = executeReturn;
  }

  self.process = process;

    // create an anonymous function to log state changes
  if( extra == null ) {
    self.AJAX.onreadystatechange = function( ) {
      self.process( self.AJAX );
    }
  } else {
    self.AJAX.onreadystatechange = function( ) {
      self.process( self.AJAX, extra );
    }
  }

  // if no method specified, then default to POST
  if( !method ) { method = "POST"; }
  method = method.toUpperCase();
  if (typeof async == 'undefined' || async == null) { async = true; }
  self.AJAX.open(method, url, async);
  if( document.cookie ) {
    self.AJAX.setRequestHeader( "Cookie", document.cookie );
  }
  if( method == "POST" ) {
    self.AJAX.setRequestHeader("Connection", "close");
    self.AJAX.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    self.AJAX.setRequestHeader("Method", "POST " + url + "HTTP/1.1");
  }
  // if dosend is true or undefined, send the request
  // only fails is dosend is false
  // you'd do this to set special request headers
  if ( dosend || typeof dosend == 'undefined' ) {
          self.AJAX.send(data);
  }
  return self.AJAX;
}

/* URL class for JavaScript
 * Copyright (C) 2003 Johan Känngård, <johan AT kanngard DOT net>
 * http://dev.kanngard.net/
 *	
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * The GPL is located at: http://www.gnu.org/licenses/gpl.txt
 */

/* Creates a new URL object with the specified url String. */
function URL(url){
	if(url.length==0) eval('throw "Invalid URL ['+url+'];');
	this.url=url;
	this.port=-1;
	this.query=(this.url.indexOf('?')>=0)?this.url.substring(this.url.indexOf('?')+1):'';
	if(this.query.indexOf('#')>=0) this.query=this.query.substring(0,this.query.indexOf('#'));
	this.protocol='';
	this.host='';
	var protocolSepIndex=this.url.indexOf('://');
	if(protocolSepIndex>=0){
		this.protocol=this.url.substring(0,protocolSepIndex).toLowerCase();
		this.host=this.url.substring(protocolSepIndex+3);
		if(this.host.indexOf('/')>=0) this.host=this.host.substring(0,this.host.indexOf('/'));
		var atIndex=this.host.indexOf('@');
		if(atIndex>=0){
			var credentials=this.host.substring(0,atIndex);
			var colonIndex=credentials.indexOf(':');
			if(colonIndex>=0){
				this.username=credentials.substring(0,colonIndex);
				this.password=credentials.substring(colonIndex);
			}else{
				this.username=credentials;
			}
			this.host=this.host.substring(atIndex+1);
		}
		var portColonIndex=this.host.indexOf(':');
		if(portColonIndex>=0){
			this.port=this.host.substring(portColonIndex);
			this.host=this.host.substring(0,portColonIndex);
		}
		this.file=this.url.substring(protocolSepIndex+3);
		this.file=this.file.substring(this.file.indexOf('/'));
	}else{
		this.file=this.url;
	}
	if(this.file.indexOf('?')>=0) this.file=this.file.substring(0, this.file.indexOf('?'));
	var refSepIndex=url.indexOf('#');
	if(refSepIndex>=0){
		this.file=this.file.substring(0,refSepIndex);
		this.reference=this.url.substring(this.url.indexOf('#')+1);
	}else{
		this.reference='';
	}
	this.path=this.file;
	if(this.query.length>0) this.file+='?'+this.query;
	if(this.reference.length>0) this.file+='#'+this.reference;

	this.getPort=getPort;
	this.getQuery=getQuery;
	this.getProtocol=getProtocol;
	this.getHost=getHost;
	this.getUserName=getUserName;
	this.getPassword=getPassword;
	this.getFile=getFile;
	this.getReference=getReference;
	this.getPath=getPath;
	this.getArgumentValue=getArgumentValue;
	this.getArgumentValues=getArgumentValues;
	this.toString=toString;

	/* Returns the port part of this URL, i.e. '8080' in the url 'http://server:8080/' */
	function getPort(){
		return this.port;
	}

	/* Returns the query part of this URL, i.e. 'Open' in the url 'http://server/?Open' */
	function getQuery(){
		return this.query;
	}

	/* Returns the protocol of this URL, i.e. 'http' in the url 'http://server/' */
	function getProtocol(){
		return this.protocol;
	}

	/* Returns the host name of this URL, i.e. 'server.com' in the url 'http://server.com/' */
	function getHost(){
		return this.host;
	}

	/* Returns the user name part of this URL, i.e. 'joe' in the url 'http://joe@server.com/' */
	function getUserName(){
		return this.username;
	}

	/* Returns the password part of this url, i.e. 'secret' in the url 'http://joe:secret@server.com/' */
	function getPassword(){
		return this.password;
	}

	/* Returns the file part of this url, i.e. everything after the host name. */
	function getFile(){
		return this.file;
	}

	/* Returns the reference of this url, i.e. 'bookmark' in the url 'http://server/file.html#bookmark' */
	function getReference(){
		return this.reference;
	}

	/* Returns the file path of this url, i.e. '/dir/file.html' in the url 'http://server/dir/file.html' */
	function getPath(){
		return this.path;
	}

	/* Returns the FIRST matching value to the specified key in the query.
	   If the url has a non-value argument, like 'Open' in '?Open&bla=12', this method
	   returns the same as the key: 'Open'...
	   The url must be correctly encoded, ampersands must encoded as &amp;
	   I.e. returns 'value' if the key is 'key' in the url 'http://server/?Open&amp;key=value' */
	function getArgumentValue(key){
		var a=this.getArgumentValues();
		if(a.length<1) return '';
		for(i=0;i<a.length;i++){
			if(a[i][0]==key) return a[i][1];
		}
		return '';
	}

	/* Returns all key / value pairs in the query as a two dimensional array */
	function getArgumentValues(){
		var a=new Array();
    var myReg = /(;|&|&amp;)/
		var b=this.query.split(myReg);
		var c='';
		if(b.length<1) return a;
		for(i=0;i<b.length;i++){
			c=b[i].split('=');
			a[i]=new Array(c[0],((c.length==1)?c[0]:c[1]));
		}
		return a;
	}

	/* Returns a String representation of this url */
	function toString(){
		return this.url;
	}
}

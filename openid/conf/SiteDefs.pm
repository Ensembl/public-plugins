package EnsEMBL::OpenID::SiteDefs;

### SiteDefs additions for openid plugin

use strict;

sub update_conf {

  $SiteDefs::ENSEMBL_OPENID_ENABLED        = 1;

  ## List of openid login providers
  ## If endpoint url needs user name, leave "[USERNAME]" in as a placeholder
  ## These gets listed as "login via" options on login page in the same order as here
  ## Save corresponding icons (120px x 45px) in htdocs/i folder (eg. openid_google.png for Google, openid_myopenid.png for MyOpenID) - all in lower case
  ## The providers with trusted key as 1 are trusted to provide genuine email address of the user. We skip the email verification process for the trusted ones.
  $SiteDefs::OPENID_PROVIDERS             ||= [
    'Google'    => {'url' => 'http://www.google.com/accounts/o8/id', 'trusted' => 1, 'trademark_owner' => 'Google Inc.'},
    'Yahoo'     => {'url' => 'https://me.yahoo.com/',                'trusted' => 1, 'trademark_owner' => 'Yahoo Inc.'},
    'MyOpenID'  => {'url' => 'https://myopenid.com/',                'trusted' => 0, 'trademark_owner' => 'MyOpenID'},
    'AOL'       => {'url' => 'http://openid.aol.com/[USERNAME]',     'trusted' => 0, 'trademark_owner' => 'AOL Inc.'}
  ];

  ## Openid Consumer secret key provided while doing openid authentication
  ## Change this in your plugins
  $SiteDefs::OPENID_CONSUMER_SECRET       ||= 'abcdefghij';
}

1;

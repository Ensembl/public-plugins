=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Admin::SiteDefs;

### SiteDefs for the Admin site
### If you are using this plugin, change the required constants from this file (along with the ones in EnsEMBL::Web:SiteDefs) by overriding them in your plugin presiding over this plugin

use strict;

sub update_conf {

  ## Allowable data objects
  $SiteDefs::OBJECT_TO_CONTROLLER_MAP = {

    Healthcheck     => 'Page',

    UserDirectory   => 'Page',

    AnalysisDesc    => 'Modal',
    Biotype         => 'Modal',
    Changelog       => 'Modal',
    Metakey         => 'Modal',
    Production      => 'Modal',
    Species         => 'Modal',
    SpeciesAlias    => 'Modal',
    Webdata         => 'Modal',
    AttribType      => 'Modal',
    Attrib          => 'Modal',
    AttribSet       => 'Modal',
    ExternalDb      => 'Modal',

    HelpRecord      => 'Modal',
    HelpLink        => 'Modal',

    Documents       => 'Page',

    Account         => 'Modal',
  };

  $SiteDefs::ENSEMBL_MART_ENABLED   = 0;
  $SiteDefs::ENSEMBL_MEMCACHED      = {};

  ## Databases used in Rose::Db::Object derived objects
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'healthcheck'} = 'DATABASE_HEALTHCHECK';
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'website'}     = 'DATABASE_WEBSITE';
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'production'}  = 'DATABASE_PRODUCTION';

  ## ID of the admin group (user group that can access the admin website)
  $SiteDefs::ENSEMBL_WEBADMIN_ID = 0;

  ## First release from which healthcheck started
  $SiteDefs::ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE = 0;

  ## Git branch on which the website code is updated to on the servers
  ## Help Images and documents will use this branch for git push and pull
  $SiteDefs::WEBSITE_GIT_BRANCH = 'master';

  ## Folders being used by the website are not same as the one to be used by git web interface (Help images and relco docs)
  $SiteDefs::WEBSITE_GIT_FOLDER_SUFFIX = '-readonly';

  ## List of database servers hosting species tables (used in healthcheck pages to display list of all databases)
  $SiteDefs::ENSEMBL_WEBADMIN_DB_SERVERS = [{
    host => 'myserver',
    port => '3306',
    user => 'myuser',
    pass => 'mypassword'
  }];

  ## List of Admin Documents
  $SiteDefs::ENSEMBL_WEBADMIN_DOCUMENTS = [
#    'URLPart'    => {'title' => 'Document title',            'location' => 'path/to/xyzdocument.txt',  'readonly' => 0 }
#    'RelCoDoc'   => {'title' => 'Release Coordination Doc',  'location' => 'path/to/relcodoc.txt',     'readonly' => 1 },
#    'TestCases'  => {'title' => 'Testcases Doc',             'location' => 'path/to/textcasesdoc.txt', 'readonly' => 0 },
  ];
}

1;

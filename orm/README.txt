********************* ORM PLUGIN *********************

This plugin is ORM API  that can be used to be able to
access the non-genomic datadase in ensembl. The plugin
is based in Rose::DB suite, requiring  installation of
the Rose::DB ORM suite  and its dependencies.

DO NOT MODIFY ANY FILE IN THIS  PLUGIN. IF ANY SORT OF
CUSTOMISATION IS  NEEDED, INHERIT THE REQUIRED CLASSES
OR USE THE CUSTOMISATION METHODS PROVIDED

------------------------------------------------------

To  be able  to add custom  database mapping  with the
help of this plugin, create a folder, ORM inside  your
modules folder and place  these  files at  appropriate
location:

* EnsEMBL::ORM::Rose::Object::[Table]

      an ORM module  to model  your database table (if
      you  have  linked  tables,  you  will  need  one
      class  inheited from  EnsEMBL::ORM::Rose::Object
      per table, with relationships defined).

* EnsEMBL::ORM::Rose::Manager::[Table]

      a companion  module  to  the  above (usually you
      need  one  per  "real" data  table  many-to-many
      linking tables don't generally need  a manager).
      (Inherited   from   EnsEMBL::ORM::Rose::Manager)
      Additional data  manupulation and mining methods
      should  be  added  to  this  manager class. This
      static manager class can easily be obtained from
      Web::Object
    

$SiteDefs::ROSE_DB_DATABASES

      Add db connection details to this hashref in ini
      file in the conf folder of your plugin.

------------------------------------------------------

In order  to create  a CRUD  interface  for a database
table (or  set of linked tables), you  will  need  the
following  (inserting  the appropriate names  into the
placeholders)

* EnsEMBL::Web::Object::[Table]

      a Web::Object::DbFrontend drived class acting as
      a wrapper for the ORM object. Override  some  of
      configuration methods to  customise the frontend

DbFrontend's Web::Component  files  are  already there
in this  plugin, but  can be  inherited  to modify the
frontend. Changes  to  the  Web::Configuration  drived
class will be required accordingly.

At  the  moment,  only  one   table  (along  with  its
relationships)  can be  mapped to  a frontend. Feature
to enable  multiple  domain  editing  is  still  under
development.

------------------------------------------------------

GETTING AJAXY DBFRONTEND PAGES WORKING

If there  is  no  customisation  in  the  pages, Ajaxy
dbfrontent interface should  work without  any trouble
as long as  Web::Object  drived object for  the plugin
page has sub use_ajax return true value, and  value of
OBJECT_TO_SCRIPT for the given page type is configured
as 'Modal'.


But if pages are  customised, JavaScript may also need
to be customised.

Any method  inside  DbFrontendRow.js/DbFrontendList.js
can be overridden/modified easily by using 'prototype'
or 'extend' methods  provided  in Base.js to customise
the page.
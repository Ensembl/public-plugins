********************* ORM PLUGIN *********************

This plugin is the  generic CRUD frontend for  the ORM
API  used  to  access  the  non-genomic   datadase  in
ensembl.

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

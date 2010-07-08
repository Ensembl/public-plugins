*** This plugin is currently under development *** 

It will eventually contain all non-essential Ensembl functionality that requires 
access to non-genomic databases, including user accounts, news, and the database 
frontend framework. Display of online help will still be possible without this plugin.

Note that use of this plugin requires installation of the Rose::DB ORM suite and its 
dependencies, which is why the above-mentioned functionality is being isolated in a plugin.

---------------------------------------------------------------------------

In order to create a CRUD interface for a database table (or set of linked tables), you
will need the following (inserting the appropriate names into the placeholders):

* EnsEMBL::[Plugin]::Rose::Object::[Table]    an ORM module to model your database table
                                              (if you have linked tables, you will need 
                                              one Rose::Object per table, with relationships 
                                              defined)
* EnsEMBL::[Plugin]::Rose::Manager::[Table]   a companion module to the above
                                              (usually you need one per "real" data table 
                                              - many-to-many linking tables don't generally 
                                              need a manager)

Regardless of relationships, you only need the following for the table you are going to save changes to:

* EnsEMBL::[Plugin]::Data::Rose::[Table]      a wrapper for the ORM object, giving access to the Hub
* EnsEMBL::Web::Configuration::[Table]        a controller to add valid URLs for the interface
                                              (note that this module _has_ to be in the Web namespace 
                                              in order for it to be picked up by the core web code)


With these in place, all the CRUD pages will automagically be generated for you - you just need to link
to them from somewhere on your site. The default URLs to link to are:

/[Table]/Display (with optional parameter 'id' - one or more primary key values)
/[Table]/List (a table of records with links to the Edit form)
/[Table]/Add
/[Table]/SelectToEdit
/[Table]/SelectToDelete

Other optional modules:

* EnsEMBL::[Plugin]::DbFrontend::[Table]              popular tweaks for the standard interface
* EnsEMBL::[Plugin]::Component::[Table]::[Whatever]   additional custom pages 
                                                      (or override standard CRUD modules if needed)
* EnsEMBL::[Plugin]::Command::[Table]::[Whatever]     additional custom command nodes 
                                                      (or override standard CRUD modules if needed)


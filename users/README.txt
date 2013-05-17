This plugin contains the new and modified user login and user groups functionality. This plugin replaces the
existing code that dealt with the user accounts. The old user database schema is not compatible with this
plugin and for the existing users accounts database to work with this plugin, a new script is provided which
copies all the existing user data to the new schema. This script is placed in the public-plugins/users/utils/
folder, and contains the essential usage information.

The user plugin requires use of another plugin, placed in public-plugins folder called 'orm' which in turn has
a dependency on Rose::DB::Object (on CPAN). Thus for the users plugin to work, Rose must be installed and the
plugins file needs to contain two extra declarations above the EnsEMBL::Ensembl declaration.

'EnsEMBL::Users' => $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/users',
'EnsEMBL::ORM' => $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/orm',
'EnsEMBL::Ensembl' => $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/ensembl'

If any of your plugin is setting the value of ENSEMBL_LOGINS to 1, it should be removed as ENSEMBL_LOGINS is
set to 1 (by this plugin itself) only if this plugin is being used.

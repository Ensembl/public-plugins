###########################################################################
#                          WEBADMIN PLUGIN                                #
###########################################################################

This plugin is optional. It is used to update the ENSEMBL_WEBSITE database,
which contains help, news and other non-genomic content. We recommend that
you run this plugin on a development server then copy the database to your
production server, rather than running it on your live site! 

In order to use this plugin, you need the following options set up:

1) You must be using the user login system - it protects your database from 
unauthorised access, and the database interface logs user IDs in order to
track updates.

2) You need to set up a user group for staff who will be permitted to
access the interface. You can call this group anything you like, but it
should be kept separate from other groups.

3) Once your group is set up, look up its group id, either in the
ensembl_web_user_db database, or by looking at the 'id' parameter in the 
URL for /common/user/viewgroup when you click on the 'Manage group' link
for that group

4) Configure the group ID as the value of ENSEMBL_WEBADMIN_ID in
SiteDefs.pm, in whichever plugin contains all your server settings

5) Add the following bookmark as a shared resource for your admin group:
/common/web/admin_home

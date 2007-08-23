package EnsEMBL::WebAdmin::Configuration::Interface::Web;

### Sub-class to do web-specific interface functions

use strict;
use EnsEMBL::Web::Configuration::Interface;
use EnsEMBL::Web::Object::User;
use EnsEMBL::Web::Mailer;

our @ISA = qw( EnsEMBL::Web::Configuration::Interface );

sub save {
  my ($self, $object, $interface) = @_;

  my $script = $interface->script_name || $object->script;
  my ($success, $url);
  
  my $primary_key = $interface->data->get_primary_key;
  my $id = $object->param($primary_key);
  $interface->cgi_populate($object, $id);

  ## Record-type-specific data munging
  if ($interface->data->type eq 'movie') {
    ## Convert length into number of frames
    my ($mins, $secs) = split(':', $interface->data->length);
    my $frame_rate = $interface->data->frame_rate || 5;
    my $frame_count = ($mins * 60 + $secs) * $frame_rate;
    $interface->data->frame_count($frame_count);
  
    ## Inform webteam that a file has been uploaded
    my $user_id = $ENV{'ENSEMBL_USER_ID'};
    my $user = EnsEMBL::Web::Object::User->new({'id'=>$user_id});
    my $user_name = $user->name;
    my $file = $interface->data->filename;
    my $mailer = EnsEMBL::Web::Mailer->new();
    $mailer->email('ap5@sanger.ac.uk');
    $mailer->subject('New Help Movie uploaded');
    $mailer->message(qq(Web admin member $user_name has uploaded a new help movie file to the server.

The file name is $filename and should have been saved to sanger-plugins/htdocs/flash/.

Please check the server and commit the file to CVS.

Thanks!));
  }

  $success = $interface->data->save;

  if ($success) {
    ## redirect to confirmation page 
    $url = "/common/$script?dataview=success";
  }
  else {
    $url = "/common/$script?dataview=failure";
  }
  return $url;
}

1;

package EnsEMBL::WebAdmin::Configuration::User;

### Configuration for all views based on the User object, including
### account management 

use strict;
use EnsEMBL::Web::Configuration;
use EnsEMBL::Web::RegObj;

our @ISA = qw( EnsEMBL::Web::Configuration );

sub admin_home {
  my $self   = shift;

  if (my $panel = $self->new_panel( 'Image',
    'code'    => "info$self->{flag}",
    'object'  => $self->{object},
    'caption' => 'Database front end for ensembl_website',
    ) ) {
    $panel->add_components(qw(
        admin_home       EnsEMBL::WebAdmin::Component::User::admin_home
    ));

    ## add panel to page
    $self->add_panel( $panel );
  }
}

sub admin_menu {
  my $self = shift;

  my $flag = 'user';
    $self->add_block( $flag, 'bulleted', "Website Database" );

    $self->add_entry( $flag, 'text' => "View old articles",
                                    'href' => "/common/web/old_help_article" );
}

1;



package EnsEMBL::Web::Configuration::UserDirectory;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Configuration);

sub caption       { 'User Directory'; }
sub short_caption { 'User Directory'; }

sub set_default_action {
  shift->{'_data'}{'default'} = 'View';
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  $page->remove_body_element($_) for qw(tabs summary);
}

sub populate_tree {
  my $self = shift;

  $self->create_node( 'View', "View all",
    [qw(
      session_info    EnsEMBL::Admin::Component::UserDirectory
    )],
    { 'availability' => 1, 'filters' => [qw(WebAdmin)]}
  );
}

1;
                  

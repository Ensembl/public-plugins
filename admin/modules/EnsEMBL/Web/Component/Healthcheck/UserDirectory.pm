package EnsEMBL::Web::Component::Healthcheck::UserDirectory;

### 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Healthcheck);
use EnsEMBL::Web::Data::Group;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $html;

  my $group = EnsEMBL::Web::Data::Group->new($object->species_defs->ENSEMBL_WEBADMIN_ID);
  my @members = sort {$a->user_id <=> $b->user_id} $group->members;
  if (scalar(@members)) {
    my $table = EnsEMBL::Web::Document::SpreadSheet->new();
    $table->add_columns(
      {'key' => 'id', 'title' => 'User ID', 'width' => '10%'},
      {'key' => 'name', 'title' => 'Name', 'width' => '30%'},
      {'key' => 'email', 'title' => 'Email', 'width' => '60%'},
    );
    foreach my $user (@members) {
      next unless $user->member_status eq 'active';
      $table->add_row({
        'id' => $user->user_id,
        'name' => $user->name,
        'email' => '<a href="mailto:'.$user->email.'">'.$user->email.'</a>',
      });
    }
    $html .= $table->render;
  }
  return $html;
}

1;

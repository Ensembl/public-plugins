package EnsEMBL::Admin::Component::UserDirectory;

use strict;

use base qw(EnsEMBL::Web::Component);

use Encode;

sub caption { ''; }

sub content {
  my $self = shift;
  
  my $admin_group   = $self->object->rose_object;
  my $admin_members = $admin_group ? $admin_group->memberships : [];

  return '<p>No User found.</p>' unless scalar @$admin_members;

  my $table = $self->new_table([], [], {'class' => 'tint'});
  $table->add_columns(
    {'key' => 'name',   'title' => 'Name',    'width' => '30%'},
    {'key' => 'email',  'title' => 'Email',   'width' => '60%'},
  );
  for (@$admin_members) {
    $_ = $_->user or next;
    $table->add_row({
      'name'  => encode("utf8", $_->name),
      'email' => '<a href="mailto:'.$_->email.'">'.$_->email.'</a>',
    });
  }
  return $table->render;
}

1;
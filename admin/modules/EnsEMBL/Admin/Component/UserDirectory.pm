package EnsEMBL::Admin::Component::UserDirectory;

use strict;

use base qw(EnsEMBL::Web::Component);

sub caption { ''; }

sub content {
  my $self = shift;
  
  my $admin_group = $self->object->rose_object;

  return '<p class="hc_p">No User found.</p>'  unless $admin_group && scalar @{$admin_group->membership};

  my $table = $self->new_table;
  $table->add_columns(
    {'key' => 'name',   'title' => 'Name',    'width' => '30%'},
    {'key' => 'email',  'title' => 'Email',   'width' => '60%'},
  );
  for (@{$admin_group->membership}) {
    $_ = $_->user or next;
    $table->add_row({
      'name'  => $_->name,
      'email' => '<a href="mailto:'.$_->email.'">'.$_->email.'</a>',
    });
  }
  return $table->render;
}

1;
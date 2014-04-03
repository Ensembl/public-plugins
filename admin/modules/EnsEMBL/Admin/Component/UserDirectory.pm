=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Admin::Component::UserDirectory;

use strict;

use parent qw(EnsEMBL::Web::Component);

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
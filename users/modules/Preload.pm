package Preload;

use strict;
use warnings;

preload_orm('users', ['user'], sub {
  require ORM::EnsEMBL::DB::Accounts::Object::User;
  require ORM::EnsEMBL::DB::Accounts::Object::Membership;
  require ORM::EnsEMBL::DB::Accounts::Object::RecordOwner;
  require ORM::EnsEMBL::DB::Accounts::Object::Login;
  require ORM::EnsEMBL::DB::Accounts::Object::Group;
  require ORM::EnsEMBL::DB::Accounts::Object::Record;
});

1;

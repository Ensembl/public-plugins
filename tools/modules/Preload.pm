package Preload;

use strict;
use warnings;

preload_orm('tools', ['ticket'], sub {
  require ORM::EnsEMBL::DB::Tools::Manager::TicketType;
  require ORM::EnsEMBL::DB::Tools::Manager::Ticket;
  require ORM::EnsEMBL::DB::Tools::Object::JobMessage;
  require ORM::EnsEMBL::DB::Tools::Object::Job;
  require ORM::EnsEMBL::DB::Tools::Object::Result;
  require ORM::EnsEMBL::DB::Tools::Object::Ticket;
  require ORM::EnsEMBL::DB::Tools::Object::TicketType;
});

1;

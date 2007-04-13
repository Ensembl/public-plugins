CREATE TABLE session (
  last_session_no   integer unsigned NOT NULL default '0'
);
CREATE TABLE session_record (
  session_record_id integer NOT NULL primary key,
  session_id        integer unsigned NOT NULL default '0',
  type_id           integer unsigned NOT NULL default '0',
  code              varchar NOT NULL default '',
  data              text NOT NULL,
  created_at        timestamp NOT NULL default '0000-00-00 00:00:00',
  modified_at       timestamp NOT NULL default '0000-00-00 00:00:00'
);
CREATE TABLE type (
  type_id integer NOT NULL primary key ,
  code varchar(64) NOT NULL default ''
);
CREATE UNIQUE INDEX code on type (code);
CREATE UNIQUE INDEX session_id on session_record (session_id,type_id,code);

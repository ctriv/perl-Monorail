#!perl

use strict;
use warnings;
use Monorail::SQLTrans::Producer::PostgreSQL;
use SQL::Translator::Schema::View;
use SQL::Translator::Schema::Procedure;

use Test::More tests => 5;

isa_ok('Monorail::SQLTrans::Producer::PostgreSQL', 'SQL::Translator::Producer::PostgreSQL');

my $view1 = SQL::Translator::Schema::View->new(
    name   => 'view_foo',
    fields => [qw/id name/],
    sql    => 'SELECT id, name FROM thing',
);

my $alter_view = Monorail::SQLTrans::Producer::PostgreSQL::alter_view($view1, {no_comments => 1});
my $alter_view_expected = 'CREATE OR REPLACE VIEW view_foo ( id, name ) AS
    SELECT id, name FROM thing
';

is($alter_view, $alter_view_expected, 'alter_view works');

my $procedure = SQL::Translator::Schema::Procedure->new(
    name => 'foo',
    extra => {
        returns => 'trigger',
        language => 'plpgsql'
    },
    parameters => ['arg integer', 'another text'],
    sql => <<'END_OF_SQL',
BEGIN
    UPDATE t_test1 SET f_timestamp=NOW() WHERE id=NEW.product_no;
    RETURN NEW;
END
END_OF_SQL
);

my $create_procedure_expected = <<'END_OF_SQL';
CREATE FUNCTION foo (arg integer, another text) RETURNS trigger LANGUAGE plpgsql AS $__SQL_TRANS_SEP__$
BEGIN
    UPDATE t_test1 SET f_timestamp=NOW() WHERE id=NEW.product_no;
    RETURN NEW;
END

$__SQL_TRANS_SEP__$
END_OF_SQL
chomp($create_procedure_expected);

my $create_procedure_produced = Monorail::SQLTrans::Producer::PostgreSQL::create_procedure($procedure);

is($create_procedure_produced, $create_procedure_expected, 'create procedure sql is correct');

my $alter_procedure_expected = <<'END_OF_SQL';
CREATE OR REPLACE FUNCTION foo (arg integer, another text) RETURNS trigger LANGUAGE plpgsql AS $__SQL_TRANS_SEP__$
BEGIN
    UPDATE t_test1 SET f_timestamp=NOW() WHERE id=NEW.product_no;
    RETURN NEW;
END

$__SQL_TRANS_SEP__$
END_OF_SQL
chomp($alter_procedure_expected);

my $alter_procedure_produced = Monorail::SQLTrans::Producer::PostgreSQL::alter_procedure($procedure);

is($alter_procedure_produced, $alter_procedure_expected, 'alter procedure sql is correct');


my $drop_procedure_expected = 'DROP FUNCTION foo (arg integer, another text)';

my $drop_procedure_produced = Monorail::SQLTrans::Producer::PostgreSQL::drop_procedure($procedure);

is($drop_procedure_produced, $drop_procedure_expected, 'drop procedure sql is correct');

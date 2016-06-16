#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropConstraint;
use Monorail::Change::CreateConstraint;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table       => 'epcot',
            name        => 'uniq_epcot_name_idx',
            type        => 'unique',
            field_names => [qw/name/],
        );
        $sut = Monorail::Change::DropConstraint->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot DROP CONSTRAINT uniq_epcot_name_idx/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropConstraint'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        my $table = $schema->add_table(name => 'epcot');

        $table->add_field(
            name           => 'name',
            data_type      => 'text',
            is_nullable    => 0,
            is_primary_key => 1,
            is_unique      => 0,
            default_value  => undef,
        );
        $table->add_constraint(
            name        => 'uniq_epcot_name_idx',
            type        => 'unique',
            field_names => [qw/name/],
        );

        $sut->transform_schema($schema);

        my ($uniq) = $schema->get_table('epcot')->get_constraints;

        cmp_deeply($uniq, undef);

    };

    it 'manipulates an in-memory dbix' => sub {
        my $dbix      = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
        my $table_add = Monorail::Change::CreateTable->new(
            name => 'epcot',
            fields => [
                {
                    name           => 'name',
                    type           => 'text',
                    is_nullable    => 1,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                },
            ],
            db_type => 'SQLite'
        );
        $table_add->transform_dbix($dbix);

        my $index_add = Monorail::Change::CreateConstraint->new(%sut_args);
        $index_add->transform_dbix($dbix);

        $sut->transform_dbix($dbix);


        my %uniqs = $dbix->source('epcot')->unique_constraints;
        cmp_deeply($uniqs{$sut->name}, undef);
    }
};

runtests;

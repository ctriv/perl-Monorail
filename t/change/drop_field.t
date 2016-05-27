#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropField;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table          => 'epcot',
            name           => 'description',
        );
        $sut = Monorail::Change::DropField->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot DROP COLUMN description/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropField'),
            methods(%sut_args),
        ));
    };

    it 'manipulates an in-memory schema' => sub {
        my $schema = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
        my $table_add = Monorail::Change::CreateTable->new(
            name => 'epcot',
            fields => [
                {
                    name           => 'description',
                    type           => 'text',
                    is_nullable    => 1,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                },
            ],
            db_type => 'SQLite'
        );

        $table_add->transform_model($schema);

        $sut->db_type('SQLite');

        $sut->transform_model($schema);

        ok(not $schema->source('epcot')->has_column('description'));
    };
};

runtests;

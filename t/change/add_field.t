#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::AddField;
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
            type           => 'TEXT',
            is_nullable    => 1,
            is_primary_key => 0,
            is_unique      => 0,
            default_value  => undef,
        );
        $sut = Monorail::Change::AddField->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot ADD COLUMN description TEXT/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::AddField'),
            methods(%sut_args),
        ));
    };

    it 'manipulates an in-memory dbix' => sub {
        my $dbix      = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
        my $table_add = Monorail::Change::CreateTable->new(
            name => 'epcot',
            fields => [
                {
                    name           => 'id',
                    type           => 'integer',
                    is_nullable    => 1,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                },
            ],
            db_type => 'SQLite'
        );

        $table_add->transform_dbix($dbix);

        $sut->db_type('SQLite');

        $sut->transform_dbix($dbix);


        my $col = $dbix->source('epcot')->column_info('description');

        cmp_deeply($col, {
            default_value => undef,
            data_type     => re(qr/text/i),
            is_nullable   => 1,
            size          => undef,
        });
    };

    it 'transforms a schema object' => sub {
        my $schema = SQL::Translator::Schema->new();
        $schema->add_table(name => 'epcot');

        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_table('epcot')->get_field('description'),
            methods(
                name      => 'description',
                data_type => 'TEXT',
            )
        );
    }
};

runtests;

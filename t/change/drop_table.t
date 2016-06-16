#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropTable;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name => 'epcot',
        );
        $sut = Monorail::Change::DropTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/DROP TABLE epcot/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropTable'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new();
        $schema->add_table(name => 'epcot');

        $sut->transform_schema($schema);
        
        my @tables = $schema->get_tables;
        cmp_deeply(\@tables, []);
    };

    it 'manipulates an in-memory dbix' => sub {
        my $dbix      = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
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

        $table_add->transform_dbix($dbix);

        $sut->db_type('SQLite');

        $sut->transform_dbix($dbix);

        my $has_epcot = grep { $_ eq 'epcot' } $dbix->sources;

        ok(not $has_epcot);
    };
};

runtests;

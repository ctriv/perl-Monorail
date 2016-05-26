#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An create table change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
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
        );
        $sut = Monorail::Change::CreateTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        my @sql = $sut->as_sql;
        like($sql[0], qr/CREATE TABLE epcot\s+\(\s+id/si);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::CreateTable'),
            methods(%sut_args),
        ));
    };

    it 'manipulates an in-memory schema' => sub {
        my $schema = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });

        $sut->db_type('SQLite');

        $sut->transform_model($schema);

        my $col = $schema->source('epcot')->column_info('id');

        cmp_deeply($col, superhashof({
            default_value => undef,
            data_type     => re(qr/integer/i),
            is_nullable   => 0
        }));
    }
};

runtests;

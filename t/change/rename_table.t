#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::RenameTable;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            new_name => 'epcot',
            old_name => 'epcot_center',
        );
        $sut = Monorail::Change::RenameTable->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot_center RENAME TO epcot/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::RenameTable'),
            methods(%sut_args),
        ));
    };

    it 'manipulates an in-memory dbix' => sub {
        my $dbix      = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
        my $table_add = Monorail::Change::CreateTable->new(
            name => 'epcot_center',
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

        ok($has_epcot);

        is($dbix->source('epcot')->name, 'epcot');

        my $has_epcot_center = grep { $_ eq 'epcot_center' } $dbix->sources;

        ok(!$has_epcot_center);
    };
};

runtests;

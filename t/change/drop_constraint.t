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
        like($sut->as_sql, qr/LTER TABLE epcot DROP CONSTRAINT uniq_epcot_name_idx/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropConstraint'),
            methods(%sut_args),
        ));
    };

    it 'manipulates an in-memory schema' => sub {
        my $schema = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
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
        $table_add->transform_model($schema);

        my $index_add = Monorail::Change::CreateConstraint->new(%sut_args);
        $index_add->transform_model($schema);

        $sut->transform_model($schema);


        my %uniqs = $schema->source('epcot')->unique_constraints;
        cmp_deeply($uniqs{$sut->name}, undef);
    }
};

runtests;

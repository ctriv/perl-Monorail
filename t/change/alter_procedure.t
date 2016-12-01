#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::AlterProcedure;

describe 'An alter procedure change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name       => 'epcot',
            parameters => [qw/ride wait_time/],
            sql        => q/select ride, wait_time from rides where park='epcot'/,
        );
        $sut = Monorail::Change::AlterProcedure->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        my @sql = $sut->as_sql;
        like($sql[0], qr/CREATE OR REPLACE FUNCTION epcot\s+\(ride/si);
        like($sql[0], qr/$sut_args{sql}/si);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::AlterProcedure'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $schema->add_procedure(
            name   => 'epcot',
            fields => [qw/ride wait_time/],
            sql    => q/select ride, wait_time from rides where park_name='Epcot'/,
        );

        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_procedure($sut_args{name}),
            methods(
                name       => 'epcot',
                sql        => $sut_args{sql},
            )
        );
    };
};

runtests;

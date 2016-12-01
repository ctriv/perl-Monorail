#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateProcedure;

describe 'A create procedure change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name       => 'epcot',
            parameters => [qw/ride wait_time/],
            sql        => q/select ride, wait_time from rides where park='epcot'/,
        );
        $sut = Monorail::Change::CreateProcedure->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        my @sql = $sut->as_sql;
        like($sql[0], qr/CREATE FUNCTION epcot\s+\(ride/si);
        like($sql[0], qr/$sut_args{sql}/si);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::CreateProcedure'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new;
        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_procedure($sut_args{name}),
            methods(
                name       => 'epcot',
                sql        => $sut_args{sql},
                parameters => $sut_args{parameters},
            )
        );
    };
};

runtests;

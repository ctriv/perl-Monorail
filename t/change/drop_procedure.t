#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::DropProcedure;

describe 'A drop procedure change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            name       => 'epcot',
            parameters => [qw/ride wait_time/],
        );
        $sut = Monorail::Change::DropProcedure->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        my @sql = $sut->as_sql;
        like($sql[0], qr/DROP FUNCTION epcot\s+\(ride/si);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::DropProcedure'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema' => sub {
        my $schema = SQL::Translator::Schema->new();
        $schema->add_procedure(name => 'epcot');

        $sut->transform_schema($schema);

        my @tables = $schema->get_procedures;
        cmp_deeply(\@tables, []);
    };
};

runtests;

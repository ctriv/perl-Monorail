#!perl

use Test::Spec;
use Test::Exception;

{
    package My::Sut;

    use Moose;

    has dbix => (
        is => 'ro',
        isa => 'Object'
    );

    with 'Monorail::Role::DetectDbType';
}


describe 'The detect db type role db_type method' => sub {
    my ($dbix, $type);
    before each => sub {
        $dbix = stub(storage => stub(
            dbh => sub {
                return {Driver => {Name => $type}}
            }
        ));
    };

    it 'translates postgresql correctly' => sub {
        $type = 'Pg';
        my $sut = My::Sut->new(dbix => $dbix);

        is($sut->db_type, 'PostgreSQL');
    };

    it 'translates mysql correctly' => sub {
        $type = 'mysql';
        my $sut = My::Sut->new(dbix => $dbix);

        is($sut->db_type, 'MySQL');
    };

    it 'translates Oracle correctly' => sub {
        $type = 'Oracle';
        my $sut = My::Sut->new(dbix => $dbix);

        is($sut->db_type, 'Oracle');
    };

    it 'translates SQLite correctly' => sub {
        $type = 'SQLite';
        my $sut = My::Sut->new(dbix => $dbix);

        is($sut->db_type, 'SQLite');
    };

    it 'dies on unknown database types' => sub {
        $type = 'epcot';
        my $sut = My::Sut->new(dbix => $dbix);

        dies_ok {
            $sut->dbh_type;
        };
    }
};

runtests;

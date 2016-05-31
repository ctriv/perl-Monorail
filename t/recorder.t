#!perl

use Test::Spec;
use Test::Exception;
use Test::Deep;

use DBIx::Class;
use Monorail::Recorder;

describe 'A monorail recorder' => sub {
    my ($schema, $dbh, $sut);

    before each => sub {
        $dbh    = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1, PrintError => 0 });
        $schema = DBIx::Class::Schema->connect(sub { $dbh });
        $sut    = Monorail::Recorder->new(dbix => $schema);
    };

    it 'makes the migration table if needed' => sub {
        dies_ok {
            $dbh->do("SELECT * FROM $Monorail::Recorder::TableName");
        };

        $sut->is_applied('epcot');

        lives_ok {
            $dbh->do("SELECT * FROM $Monorail::Recorder::TableName");
        };
    };

    it 'gives the state of a given migration' => sub {
        ok(!$sut->is_applied('epcot'));

        $dbh->do("INSERT INTO $Monorail::Recorder::TableName (name) VALUES ('epcot')");
        ok($sut->is_applied('epcot'));
    };

    it 'marks a migration as applied' => sub {
        $sut->mark_as_applied('epcot');

        my $row = $dbh->selectrow_hashref("SELECT * FROM $Monorail::Recorder::TableName where name=?", undef, 'epcot');

        cmp_deeply($row, {id => ignore, name => 'epcot'});
    }
};

runtests;

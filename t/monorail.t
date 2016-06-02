#!perl

use Test::Spec;
use Monorail;
use Path::Class;
use FindBin;

describe 'A monorail object' => sub {
    my ($sut);
    before each => sub {
        my $schema = DBIx::Class::Schema->connect(sub {
            DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 })
        });

        $sut = Monorail->new(
            dbix    => $schema,
            basedir => dir($FindBin::Bin, qw/test-data valid-migrations/)->stringify,
        );
    };

    it 'consumes the protoschema role' => sub {
        ok(Monorail->meta->does_role('Monorail::Role::ProtoSchema'));
    };

    describe 'all_migrations method' => sub {
        it 'returns a migration script set with the correct basedir' => sub {
            is($sut->all_migrations->basedir, $sut->basedir);
        };

        it 'returns a migration script set with the correct dbix' => sub {
            cmp_ok($sut->all_migrations->dbix, '==', $sut->dbix);
        }
    };

    describe 'recorder method' => sub {
        it 'returns a recorder object with the correct dbix' => sub {
            cmp_ok($sut->recorder->dbix, '==', $sut->dbix);
        };
    };

    describe 'the make_migration method' => sub {
        my $write_file_call;
        before each => sub {
            $write_file_call = Monorail::MigrationScript::Writer->expects('write_file')
        };

        it 'calls write_file on the script writer' => sub {
            $sut->make_migration;
            ok($write_file_call->verify);
        }
    }

 };


runtests;

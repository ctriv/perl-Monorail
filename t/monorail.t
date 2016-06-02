#!perl

use Test::Spec;
use Test::Deep;

use Monorail;
use Path::Class;
use FindBin;
use lib "$FindBin::Bin/test-data/dbix-schema";
use My::Schema;

describe 'A monorail object' => sub {
    my ($sut);

    before each => sub {
        my $schema = My::Schema->connect(sub {
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
        it 'makes a writer with the right name, basedir and depends' => sub {
            Monorail::MigrationScript::Writer->expects('new')->returns(sub {
                my ($class, %args) = @_;

                cmp_deeply(\%args, {
                    name => '0003_auto',
                    basedir => $sut->basedir,
                    diff    => ignore(),
                    dependencies => [qw/0002_auto/]
                });

                return stub(write_file => 1);
            });

            $sut->make_migration();
        };

        it 'passes a given name along to the writer' => sub {
            Monorail::MigrationScript::Writer->expects('new')->returns(sub {
                my ($class, %args) = @_;

                cmp_deeply(\%args, superhashof{
                    name => 'epcot',
                });

                return stub(write_file => 1);
            });

            $sut->make_migration('epcot');
        };

        it 'calls write_file on the script writer' => sub {
            my $write_file_call = Monorail::MigrationScript::Writer->expects('write_file')->returns(1);
            $sut->make_migration;
            ok($write_file_call->verify);
        };

        it 'builds a writer with the needed upwards change' => sub {
            Monorail::MigrationScript::Writer->expects('write_file')->returns(sub {
                my ($self)  = @_;
                my @changes = map { eval $_ } @{$self->upgrade_changes};

                cmp_deeply(\@changes, [
                    all(
                        isa('Monorail::Change::AddField'),
                        methods(
                            table => 'album',
                            name  => 'engineer',
                        ),
                    )
                ]);

                return 1;
            });

            $sut->make_migration;
        };
    };

    # we're going to do a little bit of integration testing here.
    describe 'the migrate method' => sub {
        it 'sets up the schema in the database' => sub {
            $sut->migrate;

            my $dbh = $sut->dbix->storage->dbh;
            my @sql = grep { defined } @{$dbh->selectcol_arrayref('select sql from sqlite_master')};

            cmp_deeply(\@sql, superbagof(
                re(qr/create table monorail_deployed_migrations/i),
                re(qr/create table album/i),
            ));
        };

        it 'marks the migraions as applied' => sub {
            $sut->migrate;

            my $dbh = $sut->dbix->storage->dbh;

            my $applied = $dbh->selectcol_arrayref('select name from monorail_deployed_migrations');

            cmp_deeply($applied, bag(qw/0001_auto 0002_auto/))
        };

        it 'does nothing the second time it is called in the same state' => sub {
            $sut->migrate;

            my $not_applied = Monorail::Recorder->expects('mark_as_applied')->never;

            $sut->migrate;

            ok($not_applied->verify);
        };
    };
 };


runtests;

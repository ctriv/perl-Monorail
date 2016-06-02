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

 };


runtests;

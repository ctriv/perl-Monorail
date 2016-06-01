#!perl

use Test::Spec;
use DBIx::Class::Schema;
use DBI;
use Monorail::Recorder::monorail_resultset;

{
    package My::Sut;

    use Moose;

    has 'dbix' => (
        is  => 'ro',
        isa => 'DBIx::Class::Schema',
        default => sub {
            my $schema = DBIx::Class::Schema->connect(sub {
                DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 })
            });
            $schema->register_class(migrations => 'Monorail::Recorder::monorail_resultset');

            return $schema;
        }
    );

    with 'Monorail::Role::ProtoSchema';

}

describe 'The monorail protoschema Role' => sub {
    it 'requires a dbix method' => sub {
        ok(Monorail::Role::ProtoSchema->meta->requires_method('dbix'));
    };

    describe 'the protoschema method' => sub {
        my ($sut);
        before each => sub {
            $sut = My::Sut->new;
        };

        it 'starts with a schema that has a model' => sub {
            is(scalar $sut->dbix->sources, 1);
        };

        it 'returns a schema with no models' => sub {
            is(scalar $sut->protoschema->sources, 0);
        };

        it 'returns a schema with the database handle' => sub {
            cmp_ok($sut->protoschema->storage->dbh, '==', $sut->dbix->storage->dbh);
        };
    }
};

runtests;

#!perl

use Test::Spec;
use Test::Deep;
use SQL::Translator::Producer::Monorail;

describe 'The monorail sql translator producer' => sub {
    describe 'the create_table method' => sub {
        it 'should return a perl string for a CreateTable change' => sub {
            my $sqlt = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            $sqlt->add_field(
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $perl = SQL::Translator::Producer::Monorail::create_table($sqlt);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateTable'),
                methods(
                    name => 'epcot',
                    fields => [{
                        name           => 'ride',
                        type           => 'text',
                        is_nullable    => 0,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                        size           => [256],
                    }],
                ),
            ));
        };
    };

    describe 'the produce method' => sub {

    }
};

runtests;

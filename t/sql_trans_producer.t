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

    describe 'the alter_create_constraint method' => sub {
        it 'should return a perl string for a CreateConstraint change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Constraint->new(
                table            => $table,
                name             => 'epcot_uniq_idx',
                type             => 'UNIQUE',
                field_names      => [qw/ride/],
                on_delete        => '',
                on_update        => '',
                match_type       => '',
                deferrable       => 0,
                reference_table  => '',
                reference_fields => undef,
            );


            my $perl = SQL::Translator::Producer::Monorail::alter_create_constraint($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(
                    table       => 'epcot',
                    name        => 'epcot_uniq_idx',
                    type        => 'unique',
                    field_names => [qw/ride/],
                ),
            ));
        };
    };

    describe 'the alter_drop_constraint method' => sub {
        it 'should return a perl string for a DropConstraint change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Constraint->new(
                table            => $table,
                name             => 'epcot_uniq_idx',
                type             => 'UNIQUE',
                field_names      => [qw/ride/],
                on_delete        => '',
                on_update        => '',
                match_type       => '',
                deferrable       => 0,
                reference_table  => '',
                reference_fields => undef,
            );


            my $perl = SQL::Translator::Producer::Monorail::alter_drop_constraint($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::DropConstraint'),
                methods(
                    table       => 'epcot',
                    name        => 'epcot_uniq_idx',
                    type        => 'unique',
                ),
            ));
        };
    };

    describe 'the alter_create_index method' => sub {
        it 'should return a perl string for a CreateIndex change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $create = SQL::Translator::Schema::Index->new(
                table  => $table,
                name   => 'ride_idx',
                fields => [qw/ride/],
                type   => 'NORMAL',
            );

            my $perl = SQL::Translator::Producer::Monorail::alter_create_index($create);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::CreateIndex'),
                methods(
                    table  => 'epcot',
                    name   => 'ride_idx',
                    fields => [qw/ride/],
                ),
            ));
        };
    };


    describe 'the add_field method' => sub {
        it 'should return a perl string for a AddField change' => sub {
            my $table = SQL::Translator::Schema::Table->new(
                name => 'epcot'
            );

            my $field = SQL::Translator::Schema::Field->new(
                table          => $table,
                name           => 'ride',
                data_type      => 'text',
                is_nullable    => 0,
                is_primary_key => 1,
                is_unique      => 0,
                default_value  => undef,
                size           => [256],
            );

            my $perl = SQL::Translator::Producer::Monorail::add_field($field);

            my $change = eval $perl;

            cmp_deeply($change, all(
                isa('Monorail::Change::AddField'),
                methods(
                    table          => 'epcot',
                    name           => 'ride',
                    type           => 'text',
                    is_nullable    => 0,
                    is_primary_key => 1,
                    is_unique      => 0,
                    default_value  => undef,
                    size           => [256],
                ),
            ));
        };
    };

    describe 'the produce method' => sub {

    }
};

runtests;

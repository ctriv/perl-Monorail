#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::CreateConstraint;
use Monorail::Change::CreateTable;
use DBI;
use DBD::SQLite;
use DBIx::Class::Schema;

describe 'An create constraint change' => sub {
    my $sut;
    my %sut_args;
    describe 'for a unique constraint' => sub {
        before each => sub {
            %sut_args = (
                table       => 'epcot',
                name        => 'uniq_epcot_name_idx',
                type        => 'unique',
                field_names => [qw/name/],
            );
            $sut = Monorail::Change::CreateConstraint->new(%sut_args);
            $sut->db_type('PostgreSQL');
        };

        it 'produces valid sql' => sub {
            like($sut->as_sql, qr/ALTER TABLE epcot ADD CONSTRAINT uniq_epcot_name_idx UNIQUE \(name\)/i);
        };

        it 'produces valid perl' => sub {
            my $perl = $sut->as_perl;
            my $new = eval $perl;

            cmp_deeply($new, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(%sut_args),
            ));
        };

        it 'manipulates an in-memory schema' => sub {
            my $schema = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
            my $table_add = Monorail::Change::CreateTable->new(
                name => 'epcot',
                fields => [
                    {
                        name           => 'name',
                        type           => 'text',
                        is_nullable    => 1,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                    },
                ],
                db_type => 'SQLite'
            );

            $table_add->transform_model($schema);
            $sut->transform_model($schema);

            my %uniqs = $schema->source('epcot')->unique_constraints;
            cmp_deeply($uniqs{$sut->name}, $sut->field_names);
        };
    };

    describe 'for a foreign key constraint' => sub {
        before each => sub {
            %sut_args = (
                field_names      => ['album_id'],
                on_delete        => 'CASCADE',
                deferrable       => 1,
                type             => 'foreign key',
                table            => 'track',
                name             => 'track_fk_album_id',
                match_type       => '',
                on_update        => 'CASCADE',
                reference_table  => 'album',
                reference_fields => ['id'],
            );
            $sut = Monorail::Change::CreateConstraint->new(%sut_args);
            $sut->db_type('PostgreSQL');
        };

        it 'produces valid sql' => sub {
            like($sut->as_sql, qr/ALTER TABLE track ADD CONSTRAINT track_fk_album_id FOREIGN KEY \(album_id\)\s+REFERENCES album \(id\) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE/i);
        };

        it 'produces valid perl' => sub {
            my $perl = $sut->as_perl;
            my $new = eval $perl;

            cmp_deeply($new, all(
                isa('Monorail::Change::CreateConstraint'),
                methods(%sut_args),
            ));
        };

        it 'manipulates an in-memory schema' => sub {
            my $schema = DBIx::Class::Schema->connect(sub { DBI->connect('dbi:SQLite:dbname=:memory:') });
            my $track_table_add = Monorail::Change::CreateTable->new(
                name => 'track',
                fields => [
                    {
                        name           => 'album_id',
                        type           => 'interger',
                        is_nullable    => 1,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                    },
                ],
                db_type => 'SQLite'
            );

            my $album_table_add = Monorail::Change::CreateTable->new(
                name => 'album',
                fields => [
                    {
                        name           => 'id',
                        type           => 'interger',
                        is_nullable    => 1,
                        is_primary_key => 1,
                        is_unique      => 0,
                        default_value  => undef,
                    },
                ],
                db_type => 'SQLite'
            );

            $track_table_add->transform_model($schema);

            $album_table_add->transform_model($schema);
            $sut->transform_model($schema);

            my $rel1 = $schema->source('track')->relationship_info('album');
            my $rel2 = $schema->source('album')->relationship_info('tracks');

            cmp_deeply($rel1, {
                'attrs' => {
                             'is_foreign_key_constraint' => 1,
                             'accessor' => 'single',
                             'undef_on_null_fk' => 1,
                             'is_depends_on' => 1,
                             'fk_columns' => {
                                               'album_id' => 1
                                             }
                           },
                'cond' => {
                            'foreign.id' => 'self.album_id'
                          },
                'source' => 'album',
                'class' => 'album'
            });
            cmp_deeply($rel2, {
                    'source' => 'track',
                    'class' => 'track',
                    'attrs' => {
                                 'is_depends_on' => 0,
                                 'cascade_copy' => 1,
                                 'join_type' => 'LEFT',
                                 'accessor' => 'multi',
                                 'cascade_delete' => 1
                               },
                    'cond' => {
                                'foreign.album_id' => 'self.id'
                              }
            })
        };
    };
};

runtests;

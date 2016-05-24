package Monorail;


use Moose;

use Monorail::MigrationScript::Writer;
use Monorail::Recorder;

use SQL::Translator;
use SQL::Translator::Parser::DBIx::Class;
use SQL::Translator::Diff;

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has debug => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has db_type => (
    is      => 'ro',
    isa     => 'Str',
    default => 'PostgreSQL',
);

has recorder => (
    is       => 'ro',
    isa      => 'Monorail::Recorder',
    lazy     => 1,
    builder  => '_build_recorder'
);

has all_migrations => (
    is       => 'ro',
    isa      => 'Monorail::MigrationScript::Set',
    lazy     => 1,
    builder  => '_build_set_of_all_migrations',
);

with 'Monorail::Role::ProtoSchema';


# ABSTRACT: Database migrations for DBIx::Class

__PACKAGE__->meta->make_immutable;

=head1 NAME

Monorail

=head1 SYNOPSIS

   ./monorail.pl make_migration
   ./monorail.pl migrate

=head1 DESCRIPTION

This module attempts to provide a simplier and more robust way to manage
database migrations with L<DBI::Class>.

This module is not remotely ready for generate use.  It is no more than a
sketch at the moment.

=cut


sub make_migration {
    my ($self, $name) = @_;

    $name ||= $self->all_migrations->next_auto_name;

    my $schema_migrations = $self->_schema_from_current_migrations;
    my $schema_perl       = $self->_schema_from_dbix;

    my $diff = SQL::Translator::Diff->new({
        output_db              => 'Monorail',
        source_schema          => $schema_migrations,
        target_schema          => $schema_perl,
    })->compute_differences;

    my $script = Monorail::MigrationScript::Writer->new(
        name         => $name,
        basedir      => $self->basedir,
        diff         => $diff,
        dependencies => [ map { $_->name } $self->all_migrations->current_dependencies ],
    );

    if ($script->write_file()) {
        print "Created $name.\n";
    }
    else {
        print "No changes detected.\n";
    }

    return 1;
}



sub _schema_from_current_migrations {
    my ($self) = @_;

    my $proto_schema = $self->protoschema;

    foreach my $migration ($self->all_migrations->in_topological_order) {
        warn sprintf("Applying %s to the protoschema...\n", $migration->name);
        my $changes = $migration->upgrade_steps;

        foreach my $change (@$changes) {
            $change->update_dbix_schema($proto_schema)
        }
    }

    # use Data::Dumper;
    # die Dumper($proto_schema);

    return $self->_parse_dbix_class($proto_schema);
}

sub _schema_from_dbix {
    my ($self) = @_;

    return $self->_parse_dbix_class($self->dbix);
}

sub _parse_dbix_class {
    my ($self, $dbix) = @_;

    my $trans = SQL::Translator->new(
        parser      => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => {
            dbic_schema => $dbix,
            # exclude our table, as it gets handled seperately.
            sources => [
               sort { $a cmp $b }
               grep { $_ ne $self->recorder->version_resultset_name }
               $dbix->sources
            ],
        },
    );

    $trans->translate;

    return $trans->schema;
}



sub migrate {
    my ($self) = @_;

    my $txn_guard = $self->dbix->txn_scope_guard;

    local $| = 1;

    foreach my $migration ($self->all_migrations->in_topological_order) {
        next if $self->recorder->is_applied($migration->name);

        print "Applying " . $migration->name . "... ";

        $migration->upgrade($self->db_type);

        print "done.\n";

        $self->recorder->mark_as_applied($migration->name);
    }

    $txn_guard->commit;
}

sub _build_recorder {
    my ($self) = @_;

    return Monorail::Recorder->new(dbix => $self->dbix);
}


sub _build_set_of_all_migrations {
    my ($self) = @_;

    require Monorail::MigrationScript::Set;

    return Monorail::MigrationScript::Set->new(basedir => $self->basedir, dbix => $self->dbix);
}

1;
__END__

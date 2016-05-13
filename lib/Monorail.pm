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

    $name ||= $self->_next_auto_name;

    my $schema_database = $self->_schema_from_database;
    my $schema_perl     = $self->_schema_from_dbix;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $self->db_type,
        source_schema => $schema_database,
        target_schema => $schema_perl,
    })->compute_differences;

    my $script = Monorail::MigrationScript::Writer->new(
        name         => $name,
        basedir      => $self->basedir,
        diff         => $diff,
        dependencies => $self->_derive_current_dependencies(),
    );

    $script->write_file();

    return 1;
}


sub _next_auto_name {
    my ($self) = @_;

    my $base    = $self->basedir;
    my @numbers = sort { $b <=> $a }
                  map  { m/(\d+)_auto\.pl/ }
                  glob("$base/*_auto.pl");

    my $max = $numbers[0] || 0;

    return sprintf("%04d_auto", $max + 1);
}

sub _derive_current_dependencies {
    my ($self)  = @_;
    my $base    = $self->basedir;
    my @deps    = map  { m/([-\w]+)\.pl$/ }
                  glob("$base/*.pl");

    return \@deps;
}

sub _schema_from_database {
    my ($self) = @_;

    my $trans = SQL::Translator->new(
        trace       => $self->debug,
        parser      => 'DBI',
        parser_args => { dbh => $self->dbix->storage->dbh },
    );

    $trans->translate;

    my $schema = $trans->schema;

    # we remove the table that we use to track migrations internally.
    $schema->drop_table($Monorail::Recorder::TableName);
    warn "\$schema->drop_table($Monorail::Recorder::TableName);\n";

    return $schema;
}

sub _schema_from_dbix {
    my ($self) = @_;

    my $trans = SQL::Translator->new(
        parser      => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => {
            dbic_schema => $self->dbix,
            # exclude our table, as it gets handled seperately.
            sources => [
               sort { $a cmp $b }
               grep { $_ ne $self->recorder->version_resultset_name }
               $self->dbix->sources
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

        $migration->upgrade();

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

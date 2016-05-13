package Monorail::Migration;

use Moose::Role;

requires qw/dependencies upgrade_sql upgrade_extras downgrade_sql downgrade_extras/;

has dbix     => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);


sub upgrade {
    my ($self) = @_;

    my $schema = $self->dbix;
    my $txn_guard = $schema->txn_scope_guard;

    my @statements = @{$self->upgrade_sql};

    foreach my $statement (@{$self->upgrade_sql}) {
        $schema->storage->dbh->do($statement);
    }

    $self->upgrade_extras;

    $txn_guard->commit;
}

sub downgrade {
    my ($self) = @_;

    my $schema    = $self->dbix;
    my $txn_guard = $schema->txn_scope_guard;

    foreach my $statement (@{$self->downgrade_sql}) {
        $schema->storage->dbh->do($statement);
    }

    $self->downgrade_extras;

    $txn_guard->commit;
}

1;

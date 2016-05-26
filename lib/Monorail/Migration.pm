package Monorail::Migration;

use Moose::Role;
use Module::Find;

usesub Monorail::Change;

requires qw/dependencies upgrade_steps upgrade_extras downgrade_steps downgrade_extras/;

has dbix     => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);


sub upgrade {
    my ($self, $db_type) = @_;

    my $schema = $self->dbix;
    my $txn_guard = $schema->txn_scope_guard;

    my @changes = @{$self->upgrade_steps};

    foreach my $change (@changes) {
        $change->db_type($db_type);

        $change->transform_database($schema);
    }

    $txn_guard->commit;
}

sub downgrade {
    my ($self, $db_type) = @_;

    my $schema    = $self->dbix;
    my $txn_guard = $schema->txn_scope_guard;

    my @changes = @{$self->downgrade_steps};
    foreach my $change (@changes) {
        $change->db_type($db_type);

        $change->transform_database($schema)
    }
    
    $txn_guard->commit;
}

1;

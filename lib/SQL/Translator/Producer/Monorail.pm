package SQL::Translator::Producer::Monorail;

use strict;
use warnings;

use Module::Find;

usesub Monorail::Change;

sub produce {
    my ($trans) = @_;

    # use Data::Dumper;
    # die Dumper($trans->schema);

    my $schema = $trans->schema;
    my @changes;

    foreach my $table ($schema->get_tables) {
        push(@changes, create_table($table));

        foreach my $constraint ($table->get_constraints) {
            # not sure this is right, but having fields as primary or unique
            # seems to DTRT
            next unless $constraint->type eq 'FOREIGN KEY';

            push(@changes, alter_create_constraint($constraint));
        }

        foreach my $index ($table->get_indices) {
            push(@changes, alter_create_index($index));
        }
    }

    return @changes;
}

sub create_table {
    my ($table) = @_;

    my @fields;
    foreach my $fld ($table->get_fields) {
        push(@fields, {
        #    table          => $fld->table->name,
            name           => $fld->name,
            type           => $fld->data_type,
            is_nullable    => $fld->is_nullable,
            is_primary_key => $fld->is_primary_key,
            is_unique      => $fld->is_unique,
            default_value  => $fld->default_value,
        });
    }

    return Monorail::Change::CreateTable->new(
        name   => $table->name,
        fields => \@fields,
    )->as_perl;
}


sub alter_create_constraint {
    my ($con, $args) = @_;

    return Monorail::Change::CreateConstraint->new(
        table            => $con->table->name,
        type             => lc $con->type,
        name             => $con->name,
        field_names      => scalar $con->field_names,
        on_delete        => $con->on_delete,
        on_update        => $con->on_update,
        match_type       => $con->match_type,
        deferrable       => $con->deferrable,
        reference_table  => $con->reference_table,
        reference_fields => scalar $con->reference_fields,
    )->as_perl;
}


sub alter_drop_constraint {
    my ($con, $args) = @_;

    return Monorail::Change::DropConstraint->new(
        table       => $con->table->name,
        type        => lc $con->type,
        name        => $con->name,
        field_names => scalar $con->field_names,
    )->as_perl;

}


sub alter_create_index {
    my ($idx, $args) = @_;

    return Monorail::Change::CreateIndex->new(
        table   => $idx->table->name,
        name    => $idx->name,
        fields  => scalar $idx->fields,
        type    => lc $idx->type,
        options => scalar $idx->options,
    )->as_perl;
}


sub alter_drop_index {
    my ($idx, $args) = @_;

    use Data::Dumper;
    die Dumper($idx);
}


sub add_field {
    my ($fld, $args) = @_;

    return Monorail::Change::AddField->new(
        table          => $fld->table->name,
        name           => $fld->name,
        type           => $fld->data_type,
        is_nullable    => $fld->is_nullable,
        is_primary_key => $fld->is_primary_key,
        is_unique      => $fld->is_unique,
        default_value  => $fld->default_value,
    )->as_perl;
}


sub alter_field {
    my ($from, $to, $args) = @_;

    if ($from->table->name ne $to->table->name) {
        die "Can't alter field in another table";
    }

    my $change = Monorail::Change::AlterField->new(
        table => $from->table->name,
        from  => {
            name           => $from->name,
            type           => $from->data_type,
            is_nullable    => $from->is_nullable,
            is_primary_key => $from->is_primary_key,
            is_unique      => $from->is_unique,
            default_value  => $from->default_value,
        },
        to => {
            name           => $to->name,
            type           => $to->data_type,
            is_nullable    => $to->is_nullable,
            is_primary_key => $to->is_primary_key,
            is_unique      => $to->is_unique,
            default_value  => $to->default_value,
        }
    );

    if ($change->has_changes) {
        return $change->as_perl
    }
    else {
        return;
    }
}

#
# sub rename_field {
#     my ($old_fld, $new_fld, $args) = @_;
# }


sub drop_field {
    my ($fld, $args) = @_;

    return Monorail::Change::DropField->new(
        table => $fld->table->name,
        name  => $fld->name,
    )->as_perl;
}


# sub alter_table {
#     my ($table, $args) = @_;
# }


sub drop_table {
    my ($table, $args) = @_;

    return Monorail::Change::DropTable->new(
        name => $table->name,
    )->as_perl;
}

#
# sub rename_table {
#     my ($old_table, $new_table, $args) = @_;
# }
#

1;
__END__

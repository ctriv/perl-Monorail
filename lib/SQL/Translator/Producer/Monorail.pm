package SQL::Translator::Producer::Monorail;

use strict;
use warnings;

use Module::Find;

usesub Monorail::Change;

sub produce {
    my ($trans) = @_;

    my $schema = $trans->schema;

    my @tables = map { create_table($_) } $schema->get_tables;

    return @tables;
}

sub create_table {
    my ($table) = @_;

    my @fields;
    foreach my $fld ($table->get_fields) {
        push(@fields, {
            table          => $fld->table->name,
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
}


sub alter_drop_constraint {
    my ($con, $args) = @_;
}


sub alter_create_index {
    my ($idx, $args) = @_;
}


sub alter_drop_index {
    my ($idx, $args) = @_;
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
    my ($old_fld, $new_fld, $args) = @_;
}


sub rename_field {
    my ($old_fld, $new_fld, $args) = @_;
}


sub drop_field {
    my ($fld, $args) = @_;

    return Monorail::Change::DropField->new(
        table => $fld->table->name,
        name  => $fld->name,
    )->as_perl;
}


sub alter_table {
    my ($table, $args) = @_;
}


sub drop_table {
    my ($table, $args) = @_;

    return Monorail::Change::DropTable->new(
        name => $table->name,
    )->as_perl;
}


sub rename_table {
    my ($old_table, $new_table, $args) = @_;
}


1;
__END__

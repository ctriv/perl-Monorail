package SQL::Translator::Producer::Monorail;

use strict;
use warnings;


sub produce {
    return ''; # we don't produce a whole schema at once... yet?
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
        table => $fld->table->name,
        name  => $fld->name,
        type  => $fld->data_type,
        is_nullable => $fld->is_nullable,
        is_primary_key => $fld->is_primary_key,
        is_unique      => $fld->is_uniq,
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
}


sub alter_table {
    my ($table, $args) = @_;
}


sub drop_table {
    my ($table, $args) = @_;
}


sub rename_table {
    my ($old_table, $new_table, $args) = @_;
}


1;
__END__

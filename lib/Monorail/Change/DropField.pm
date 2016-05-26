package Monorail::Change::DropField;

use Moose;
use SQL::Translator::Schema::Field;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::DropField->new(
        table => $fld->table->name,
        name  => $fld->name,
    );

    print $add_field->as_perl;

    $add_field->as_sql;

    $add_field->update_dbix_schema($dbix)

=cut


has table          => (is => 'ro', isa => 'Str',  required => 1);
has name           => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_field;

    return $self->producer->drop_field($field);
}

sub as_sql_translator_field {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Field->new(
        table          => $table,
        name           => $self->name,
    );
}

sub transform_model {
    my ($self, $dbix) = @_;

    # This is going to need to be tweak, right now we're not tracking the
    # model's name in dbix... which means while this will work for the style
    # that we have at work - it won't work for all (or even most) dbix setups
    $dbix->source($self->table)->remove_column($self->name);
}

sub as_hashref_keys {
    return qw/name table/;
}


1;
__END__

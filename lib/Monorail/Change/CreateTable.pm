package Monorail::Change::CreateTable;

use Moose;
use Monorail::Change::AddField;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Table;
use SQL::Translator::Schema::Constraint;

with 'Monorail::Change';

has name   => (is => 'ro', isa => 'Str',                required => 1);
has fields => (is => 'ro', isa => 'ArrayRef[HashRef]',  required => 1);

__PACKAGE__->meta->make_immutable;

sub as_hashref_keys {
    return qw/name fields/;
}

sub as_sql {
    my ($self) = @_;

    my $table = $self->as_sql_translator_table;

    my ($create, $fks) = $self->producer->create_table($table);

    return ($create, @$fks);
}

sub as_sql_translator_table {
    my ($self) = @_;

    my $table = SQL::Translator::Schema::Table->new(name => $self->name);
    foreach my $field (@{$self->fields}) {
        local $field->{table} = $self->name;
        my $change = Monorail::Change::AddField->new($field);
        $table->add_field($change->as_sql_translator_field);

        if ($change->is_primary_key) {
            $table->add_constraint(
                fields => [$change->name],
                type   => 'primary_key',
            );
        }
        elsif ($change->is_unique) {
            $table->add_constraint(
                fields => [$change->name],
                type   => 'unique',
            );
        }

    }

    return $table;
}

sub update_dbix_schema {
    my ($self, $dbix) = @_;

    # This is going to need to be tweak, right now we're not tracking the
    # model's name in dbix... which means while this will work for the style
    # that we have at work - it won't work for all (or even most) dbix setups

    my ($implementation, $name, $class) = $self->anonymous_class_for_table($dbix);

    eval $implementation;
    die $@ if $@;

    $dbix->register_class($name, $class);
}

sub anonymous_class_for_table {
    my ($self, $dbix) = @_;

    my $schema_class = ref $dbix;
    my $trans = SQL::Translator->new(
        producer => 'SQL::Translator::Producer::DBIx::Class::File',
        producer_args => {
            prefix => $schema_class,
        },
    );

    $trans->schema->add_table($self->as_sql_translator_table);

    my $dbix_class_impl = $trans->producer->($trans);

    $dbix_class_impl =~ s/\n\npackage $schema_class;.*$//s;

    my $name = $self->name;
    return ($dbix_class_impl, $name, "${schema_class}::$name");

}


1;

package Monorail::Change::CreateConstraint;

use Moose;
use SQL::Translator::Schema::Constraint;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_const = Monorail::Change::CreateConstrant->new(
        table       => 'train',
        name        => 'uniq_train_name_idx',
        type        => 'unique',
        field_names => [qw/name/],
    );

    print $add_const->as_perl;

    $add_const->as_sql;

    $add_const->transform_dbix($dbix)

=cut


has table            => (is => 'ro', isa => 'Str',           required => 1);
has name             => (is => 'ro', isa => 'Str',           required => 1);
has type             => (is => 'ro', isa => 'Str',           required => 1);
has field_names      => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has on_delete        => (is => 'ro', isa => 'Str',           required => 0);
has on_update        => (is => 'ro', isa => 'Str',           required => 0);
has match_type       => (is => 'ro', isa => 'Str',           required => 0);
has deferrable       => (is => 'ro', isa => 'Bool',          required => 0);
has reference_table  => (is => 'ro', isa => 'Str',           required => 0);
has reference_fields => (is => 'ro', isa => 'ArrayRef[Str]', required => 0);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_constraint;

    return $self->producer->alter_create_constraint($field);
}

sub as_sql_translator_constraint {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Constraint->new(
        table            => $table,
        name             => $self->name,
        type             => $self->type,
        field_names      => $self->field_names,
        on_delete        => $self->on_delete,
        on_update        => $self->on_update,
        match_type       => $self->match_type,
        deferrable       => $self->deferrable,
        reference_table  => $self->reference_table,
        reference_fields => $self->reference_fields,
    );
}

sub transform_dbix {
    my ($self, $dbix) = @_;
    # This is going to need to be tweak, right now we're not tracking the
    # model's name in dbix... which means while this will work for the style
    # that we have at work - it won't work for all (or even most) dbix setups
    if ($self->type eq 'unique') {
        $dbix->source($self->table)->add_unique_constraint(
            $self->name => $self->field_names
        )
    }
    elsif ($self->type eq 'foreign key') {
        $dbix->source($self->table)->add_relationship(
            $self->reference_table,
            $self->reference_table,
            {
                'foreign.' . $self->reference_fields->[0] => 'self.' . $self->field_names->[0]
            },
            {
                'accessor' => 'single',
                'is_foreign_key_constraint' => 1,
                'fk_columns' => {
                    'album_id' => 1
                },
                'undef_on_null_fk' => 1,
                'is_depends_on' => 1
            },
        );


        $dbix->source($self->reference_table)->add_relationship(
            $self->table . 's',
            $self->table,
            {
                'foreign.' . $self->field_names->[0] => 'self.' . $self->reference_fields->[0]
            },
            {
                'is_depends_on' => 0,
                'cascade_delete' => 1,
                'accessor' => 'multi',
                'cascade_copy' => 1,
                'join_type' => 'LEFT'
            }
        );
    }
    else {
        die $self->type . " constraints are not yet supported.\n";
    }
}

sub as_hashref_keys {
    return qw/
        name table type field_names on_delete on_update match_type deferrable
        reference_table reference_fields
    /;
}

1;
__END__

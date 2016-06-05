package Monorail::Change::DropConstraint;

use Moose;
use SQL::Translator::Schema::Constraint;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_const = Monorail::Change::DropConstraint->new(
        table       => 'train',
        name        => 'uniq_train_name_idx',
        type        => 'unique',
        field_names => [qw/name/],
    );

    print $add_const->as_perl;

    $add_const->as_sql;

    $add_const->transform_dbix($dbix)

=cut


has table       => (is => 'ro', isa => 'Str',           required => 1);
has name        => (is => 'ro', isa => 'Str',           required => 1);
has type        => (is => 'ro', isa => 'Str',           required => 1);
has field_names => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_constraint;

    return $self->producer->alter_drop_constraint($field);
}

sub as_sql_translator_constraint {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Constraint->new(
        table       => $table,
        name        => $self->name,
        type        => $self->type,
        field_names => $self->field_names,
    );
}

sub transform_dbix {
    my ($self, $dbix) = @_;

    # This is going to need to be tweak, right now we're not tracking the
    # model's name in dbix... which means while this will work for the style
    # that we have at work - it won't work for all (or even most) dbix setups
    if ($self->type eq 'unique') {
        # there's no public api for doing this... perhaps will should submit
        # a pull request.
        my $uniqs = $dbix->source($self->table)->_unique_constraints;
        delete $uniqs->{$self->name}
    }
    else {
        die $self->type . " constraints are not yet supported.\n";
    }
}

sub as_hashref_keys {
    return qw/name table type field_names/;
}

1;
__END__

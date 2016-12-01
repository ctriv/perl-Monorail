package Monorail::Change::CreateProcedure;

use Moose;
use SQL::Translator::Schema::View;

with 'Monorail::Role::Change::StandardSQL';

has name       => (is => 'ro', isa => 'Str',           required => 1);
has parameters => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has sql        => (is => 'ro', isa => 'Str',           required => 1);

__PACKAGE__->meta->make_immutable;

sub as_hashref_keys {
    return qw/name parameters sql/;
}

sub as_sql {
    my ($self) = @_;

    my $proc = $self->as_sql_translator_proc;

    return $self->producer->create_procedure($proc);
}

sub as_sql_translator_proc {
    my ($self) = @_;

    return SQL::Translator::Schema::Procedure->new(
        name       => $self->name,
        parameters => $self->parameters,
        sql        => $self->sql,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->add_procedure($self->as_sql_translator_proc);
}

1;

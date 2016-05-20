package Monorail::Change::CreateIndex;

use Moose;
use SQL::Translator::Schema::Index;

with 'Monorail::Change';

=head1 SYNOPSIS

    my $crt_index = Monorail::Change::CreateIndex->new(
        table   => $idx->table->name,
        name    => $idx->name,
        fields  => scalar $idx->fields,
        type    => lc $idx->type,
        options => scalar $idx->options,
    );

    print $crt_index->as_perl;

    $crt_index->as_sql;

    $crt_index->update_dbix_schema($dbix)

=cut


has table            => (is => 'ro', isa => 'Str',           required => 1);
has name             => (is => 'ro', isa => 'Str',           required => 1);
has type             => (is => 'ro', isa => 'Str',           required => 1);
has fields           => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has options          => (is => 'ro', isa => 'ArrayRef',      required => 0);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    return $self->producer->alter_create_index($self->as_sql_translator_index);
}

sub as_sql_translator_index {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Index->new(
        table   => $table,
        name    => $self->name,
        type    => $self->type,
        fields  => $self->fields,
        options => $self->options,
    );
}

sub update_dbix_schema {
    my ($self, $dbix) = @_;

    $self->add_dbix_sqlt_callback($dbix, $self->table, sub {
        my ($rs, $sqlt_table) = @_;

        $sqlt_table->add_index($self->as_sql_translator_index);
    });
}

sub as_hashref_keys {
    return qw/
        name table type fields options
    /;
}

1;
__END__

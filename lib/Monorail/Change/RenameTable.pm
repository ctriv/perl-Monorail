package Monorail::Change::RenameTable;

use Moose;
use SQL::Translator::Schema::Table;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::RenameTable->new(
        old_name => 'epcot_center',
        new_name => 'epcot',
    );

    print $add_field->as_perl;

    $add_field->transform_database($dbix);

    $add_field->transform_dbix($dbix)

=cut


has old_name => (is => 'ro', isa => 'Str',  required => 1);
has new_name => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $old = SQL::Translator::Schema::Table->new(name => $self->old_name);
    my $new = SQL::Translator::Schema::Table->new(name => $self->new_name);

    return $self->producer->rename_table($old, $new);
}


sub transform_dbix {
    my ($self, $dbix) = @_;

    my $source = $dbix->source($self->old_name);
    $dbix->unregister_source($self->old_name);

    $source->name($self->new_name);

    $dbix->register_source($self->new_name, $source);
}

sub as_hashref_keys {
    return qw/old_name new_name/;
}


1;
__END__

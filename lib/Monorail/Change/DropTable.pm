package Monorail::Change::DropTable;

use Moose;
use SQL::Translator::Schema::Table;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::DropTable->new(
        name  => $fld->name,
    );

    print $add_field->as_perl;

    $add_field->as_sql;

    $add_field->update_dbix_schema($dbix)

=cut


has name           => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $table = SQL::Translator::Schema::Table->new(name => $self->name);

    return $self->producer->drop_table($table);
}

sub transform_model {
    my ($self, $dbix) = @_;

    # This is going to need to be tweak, right now we're not tracking the
    # model's name in dbix... which means while this will work for the style
    # that we have at work - it won't work for all (or even most) dbix setups
    $dbix->unregister_source($self->name);
}

sub as_hashref_keys {
    return qw/name/;
}


1;
__END__

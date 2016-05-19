package Monorail::Role::ProtoSchema;

use Moose::Role;

requires 'dbix';


has protoschema => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    lazy    => 1,
    builder => '_build_protoschema',
);


sub _build_protoschema {
    my ($self) = @_;

    return DBIx::Class::Schema->connect(sub { $self->dbix->storage->dbh });
}


1;
__END__
